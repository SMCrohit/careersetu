import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/tests_repository.dart';
import '../../domain/test_model.dart';

/// A paged list of tests from `GET /tests?status=...`.
class TestListState {
  final List<TestSummary> items;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const TestListState({this.items = const [], this.total = 0, this.isLoading = true, this.isLoadingMore = false, this.error});

  bool get hasMore => items.length < total;

  TestListState copyWith({List<TestSummary>? items, int? total, bool? isLoading, bool? isLoadingMore, String? error, bool clearError = false}) =>
      TestListState(
        items: items ?? this.items,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : error ?? this.error,
      );
}

class TestListNotifier extends Notifier<TestListState> {
  final String status;
  int _page = 1;

  TestListNotifier(this.status);

  @override
  TestListState build() {
    Future.microtask(refresh);
    return const TestListState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref.read(testsRepositoryProvider).fetchTests(status: status);
      _page = 1;
      state = TestListState(items: page.tests, total: page.total, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e is ApiException ? e.message : 'Could not load tests.');
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref.read(testsRepositoryProvider).fetchTests(status: status, page: _page + 1);
      _page++;
      final known = {for (final t in state.items) t.id};
      state = state.copyWith(
        items: [...state.items, ...page.tests.where((t) => !known.contains(t.id))],
        total: page.total,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

/// Active tests the user hasn't taken yet (Tests tab).
final activeTestsProvider = NotifierProvider<TestListNotifier, TestListState>(() => TestListNotifier('available'));

/// Tests the user has taken, with best scores (My Tests).
final myTestsProvider = NotifierProvider<TestListNotifier, TestListState>(() => TestListNotifier('attempted'));

/// A past result, loaded by attempt id.
final attemptResultProvider = FutureProvider.autoDispose.family<AttemptResult, String>((ref, id) {
  return ref.read(testsRepositoryProvider).fetchAttempt(id);
});

// ---------------------------------------------------------------------------
// Taking a test
// ---------------------------------------------------------------------------

class ExamState {
  final ActiveTest? test;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final int index;

  /// Selected option ids per question id.
  final Map<String, Set<String>> answers;

  /// Seconds spent per question id.
  final Map<String, int> timeSpent;

  /// Seconds left: for the whole test, or for the current question in per-question mode.
  final int timeLeft;
  final AttemptResult? result;

  const ExamState({
    this.test,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.index = 0,
    this.answers = const {},
    this.timeSpent = const {},
    this.timeLeft = 0,
    this.result,
  });

  TestQuestion? get question => test == null || test!.questions.isEmpty ? null : test!.questions[index];
  int get total => test?.questions.length ?? 0;
  bool get isLast => index >= total - 1;
  bool get isPerQuestion => test?.info.isPerQuestion ?? false;
  int get answeredCount => answers.values.where((s) => s.isNotEmpty).length;
  bool isAnswered(String questionId) => answers[questionId]?.isNotEmpty ?? false;

  ExamState copyWith({
    ActiveTest? test,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    int? index,
    Map<String, Set<String>>? answers,
    Map<String, int>? timeSpent,
    int? timeLeft,
    AttemptResult? result,
  }) =>
      ExamState(
        test: test ?? this.test,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : error ?? this.error,
        index: index ?? this.index,
        answers: answers ?? this.answers,
        timeSpent: timeSpent ?? this.timeSpent,
        timeLeft: timeLeft ?? this.timeLeft,
        result: result ?? this.result,
      );
}

class ExamNotifier extends Notifier<ExamState> {
  Timer? _timer;

  @override
  ExamState build() {
    ref.onDispose(() => _timer?.cancel());
    return const ExamState();
  }

  Future<void> start(String testId) async {
    _timer?.cancel();
    state = const ExamState(isLoading: true);
    try {
      final test = await ref.read(testsRepositoryProvider).startTest(testId);
      if (test.questions.isEmpty) {
        state = const ExamState(error: 'This test has no questions yet.');
        return;
      }
      state = ExamState(test: test, timeLeft: _timeFor(test, 0));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (e) {
      state = ExamState(error: e is ApiException ? e.message : 'Could not start the test. Please try again.');
    }
  }

  int _timeFor(ActiveTest test, int index) {
    if (test.info.isPerQuestion) return test.questions[index].timeLimitSeconds;
    final mins = test.info.durationMins > 0 ? test.info.durationMins : 10;
    return mins * 60;
  }

  void _tick() {
    final q = state.question;
    if (q == null || state.isSubmitting || state.result != null) return;
    final spent = Map<String, int>.from(state.timeSpent)..update(q.id, (v) => v + 1, ifAbsent: () => 1);
    final left = state.timeLeft - 1;
    state = state.copyWith(timeSpent: spent, timeLeft: left < 0 ? 0 : left);
    if (left > 0) return;
    // Time is up: next question in per-question mode, otherwise submit.
    if (state.isPerQuestion && !state.isLast) {
      next();
    } else {
      submit();
    }
  }

  void toggleOption(String optionId) {
    final q = state.question;
    if (q == null || state.isSubmitting) return;
    final answers = Map<String, Set<String>>.from(state.answers);
    final current = Set<String>.from(answers[q.id] ?? {});
    if (q.isMulti) {
      current.contains(optionId) ? current.remove(optionId) : current.add(optionId);
    } else {
      current
        ..clear()
        ..add(optionId);
    }
    answers[q.id] = current;
    state = state.copyWith(answers: answers);
  }

  void next() {
    final test = state.test;
    if (test == null || state.isLast) return;
    final i = state.index + 1;
    state = state.copyWith(index: i, timeLeft: state.isPerQuestion ? _timeFor(test, i) : null);
  }

  /// Going back and jumping are only allowed when the whole test shares one timer.
  void previous() {
    if (state.isPerQuestion || state.index == 0) return;
    state = state.copyWith(index: state.index - 1);
  }

  void jumpTo(int i) {
    if (state.isPerQuestion || i < 0 || i >= state.total) return;
    state = state.copyWith(index: i);
  }

  Future<void> submit() async {
    final test = state.test;
    if (test == null || state.isSubmitting || state.result != null) return;
    _timer?.cancel();
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await ref.read(testsRepositoryProvider).submitAttempt(
            testId: test.info.id,
            timeTakenSeconds: state.timeSpent.values.fold(0, (a, b) => a + b),
            answers: [
              for (final q in test.questions)
                {
                  'question_id': q.id,
                  'selected_option_ids': (state.answers[q.id] ?? {}).toList(),
                  'time_spent_seconds': state.timeSpent[q.id] ?? 0,
                },
            ],
          );
      state = state.copyWith(isSubmitting: false, result: result);
      ref.invalidate(activeTestsProvider);
      ref.invalidate(myTestsProvider);
    } catch (e) {
      // Keep the answers so the user can retry; the timer stays stopped.
      state = state.copyWith(isSubmitting: false, error: e is ApiException ? e.message : 'Could not submit. Check your connection and try again.');
    }
  }

  void reset() {
    _timer?.cancel();
    state = const ExamState();
  }
}

final examProvider = NotifierProvider<ExamNotifier, ExamState>(ExamNotifier.new);
