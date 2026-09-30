import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/tests_repository.dart';
import '../../domain/test_model.dart';
import '../../../jobs/data/jobs_repository.dart'; // to get apiClientProvider


class ActiveTestState {
  final TestModel? test;
  final int currentQuestionIndex;
  final Map<int, int> selectedAnswers;
  final int timeRemaining;
  final bool isFinished;
  final bool isLoading;

  ActiveTestState({
    this.test,
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.timeRemaining = 600, // 10 minutes
    this.isFinished = false,
    this.isLoading = false,
  });

  ActiveTestState copyWith({
    TestModel? test,
    int? currentQuestionIndex,
    Map<int, int>? selectedAnswers,
    int? timeRemaining,
    bool? isFinished,
    bool? isLoading,
  }) {
    return ActiveTestState(
      test: test ?? this.test,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isFinished: isFinished ?? this.isFinished,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ActiveTestNotifier extends Notifier<ActiveTestState> {
  Timer? _timer;

  @override
  ActiveTestState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return ActiveTestState();
  }

  Future<void> loadTest(String testId) async {
    state = ActiveTestState(isLoading: true);
    final repo = ref.read(testsRepositoryProvider);
    final test = await repo.fetchTest(testId);
    state = ActiveTestState(test: test, timeRemaining: 600);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      } else {
        submitTest();
      }
    });
  }

  void selectAnswer(int optionIndex) {
    if (state.isFinished) return;
    final newAnswers = Map<int, int>.from(state.selectedAnswers);
    newAnswers[state.currentQuestionIndex] = optionIndex;
    state = state.copyWith(selectedAnswers: newAnswers);
  }

  void nextQuestion() {
    if (state.test == null) return;
    if (state.currentQuestionIndex < state.test!.questions.length - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  void submitTest() {
    _timer?.cancel();

    // Capture score BEFORE marking finished (state mutation)
    final currentScore = score;
    final currentTestId = state.test?.id;

    state = state.copyWith(isFinished: true);

    // Persist to backend
    if (currentTestId != null) {
      ref.read(completedTestsProvider.notifier).saveScore(currentTestId, currentScore);
    }
  }

  int get score {
    if (state.test == null) return 0;
    int s = 0;
    for (int i = 0; i < state.test!.questions.length; i++) {
      if (state.selectedAnswers[i] == state.test!.questions[i].correctAnswerIndex) {
        s++;
      }
    }
    return s;
  }
}

class CompletedTestsNotifier extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.get('/users/me/test-attempts');
      final Map<String, int> scores = {};
      for (var item in response.data) {
        final String testId = item['test_id'];
        final int score = (item['score'] as num).toInt();
        // Keep highest score
        if (!scores.containsKey(testId) || score > scores[testId]!) {
          scores[testId] = score;
        }
      }
      return scores;
    } catch (e) {
      return {};
    }
  }

  Future<void> saveScore(String testId, int score) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      debugPrint('[TestAttempt] Saving score=$score for testId=$testId');
      await apiClient.post('/users/me/test-attempts', data: {
        'test_id': testId,
        'score': score.toDouble(), // backend expects Float
      });
      debugPrint('[TestAttempt] Score saved successfully');
      // Refresh local state from backend
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('[TestAttempt] ERROR saving score: $e');
      // Still update local state optimistically so UI is not broken
      final current = state.value ?? {};
      final updated = Map<String, int>.from(current);
      if (!updated.containsKey(testId) || score > (updated[testId] ?? 0)) {
        updated[testId] = score;
      }
      state = AsyncValue.data(updated);
    }
  }
}

final completedTestsProvider = AsyncNotifierProvider<CompletedTestsNotifier, Map<String, int>>(() {
  return CompletedTestsNotifier();
});

final activeTestProvider = NotifierProvider<ActiveTestNotifier, ActiveTestState>(() {
  return ActiveTestNotifier();
});

class PaginatedTestsState {
  final List<TestModel> items;
  final bool isLoading;
  final bool hasMore;
  final int currentSkip;
  final String status;

  PaginatedTestsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentSkip = 0,
    required this.status,
  });

  PaginatedTestsState copyWith({
    List<TestModel>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentSkip,
    String? status,
  }) {
    return PaginatedTestsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentSkip: currentSkip ?? this.currentSkip,
      status: status ?? this.status,
    );
  }
}

class PaginatedTestsNotifier extends Notifier<PaginatedTestsState> {
  final String status;

  PaginatedTestsNotifier(this.status);

  @override
  PaginatedTestsState build() {
    _fetchInitial();
    return PaginatedTestsState(status: status, isLoading: true);
  }

  Future<void> _fetchInitial() async {
    try {
      final repo = ref.read(testsRepositoryProvider);
      final fetched = await repo.fetchAllTests(status: status, skip: 0, limit: 20);
      state = state.copyWith(
        items: fetched,
        isLoading: false,
        hasMore: fetched.length == 20,
        currentSkip: fetched.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, hasMore: true, currentSkip: 0);
    final repo = ref.read(testsRepositoryProvider);
    try {
      final fetched = await repo.fetchAllTests(status: status, skip: 0, limit: 20);
      state = state.copyWith(
        items: fetched,
        isLoading: false,
        hasMore: fetched.length == 20,
        currentSkip: fetched.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final repo = ref.read(testsRepositoryProvider);
    try {
      final fetched = await repo.fetchAllTests(status: status, skip: state.currentSkip, limit: 20);
      state = state.copyWith(
        items: [...state.items, ...fetched],
        isLoading: false,
        hasMore: fetched.length == 20,
        currentSkip: state.currentSkip + fetched.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final availableTestsProvider = NotifierProvider<PaginatedTestsNotifier, PaginatedTestsState>(() {
  return PaginatedTestsNotifier('available');
});

final attemptedTestsProvider = NotifierProvider<PaginatedTestsNotifier, PaginatedTestsState>(() {
  return PaginatedTestsNotifier('attempted');
});
