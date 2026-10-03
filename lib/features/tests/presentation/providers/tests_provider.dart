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
  final Map<int, int> timeSpentPerQuestion;
  final int timeRemaining;
  final bool isFinished;
  final bool isLoading;
  final Map<String, dynamic>? aiReport;

  ActiveTestState({
    this.test,
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.timeSpentPerQuestion = const {},
    this.timeRemaining = 600, // 10 minutes
    this.isFinished = false,
    this.isLoading = false,
    this.aiReport,
  });

  ActiveTestState copyWith({
    TestModel? test,
    int? currentQuestionIndex,
    Map<int, int>? selectedAnswers,
    Map<int, int>? timeSpentPerQuestion,
    int? timeRemaining,
    bool? isFinished,
    bool? isLoading,
    Map<String, dynamic>? aiReport,
  }) {
    return ActiveTestState(
      test: test ?? this.test,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      timeSpentPerQuestion: timeSpentPerQuestion ?? this.timeSpentPerQuestion,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isFinished: isFinished ?? this.isFinished,
      isLoading: isLoading ?? this.isLoading,
      aiReport: aiReport ?? this.aiReport,
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

  void cancelTest() {
    _timer?.cancel();
    state = ActiveTestState();
  }

  Future<void> loadTest(String testId) async {
    state = ActiveTestState(isLoading: true);
    final repo = ref.read(testsRepositoryProvider);
    final test = await repo.fetchTest(testId);
    
    int initialTime = test.durationMins * 60;
    if (test.testMode == 'per_question' && test.questions.isNotEmpty) {
      initialTime = test.questions[0].expectedTimeSeconds > 0 
          ? test.questions[0].expectedTimeSeconds 
          : 60;
    }
    
    state = ActiveTestState(test: test, timeRemaining: initialTime);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        final newTimeSpent = Map<int, int>.from(state.timeSpentPerQuestion);
        newTimeSpent[state.currentQuestionIndex] = (newTimeSpent[state.currentQuestionIndex] ?? 0) + 1;
        
        state = state.copyWith(
          timeRemaining: state.timeRemaining - 1,
          timeSpentPerQuestion: newTimeSpent,
        );
      } else {
        if (state.test?.testMode == 'per_question') {
          if (state.currentQuestionIndex < state.test!.questions.length - 1) {
            nextQuestion();
          } else {
            submitTest();
          }
        } else {
          submitTest();
        }
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
      int nextIdx = state.currentQuestionIndex + 1;
      int nextTime = state.timeRemaining;
      
      if (state.test!.testMode == 'per_question') {
        nextTime = state.test!.questions[nextIdx].expectedTimeSeconds > 0
            ? state.test!.questions[nextIdx].expectedTimeSeconds
            : 60;
      }
      
      state = state.copyWith(
        currentQuestionIndex: nextIdx,
        timeRemaining: nextTime,
      );
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  Future<void> submitTest() async {
    _timer?.cancel();
    final currentTest = state.test;
    if (currentTest == null) return;
    
    state = state.copyWith(isLoading: true);

    int totalScore = 0;
    int totalTime = 0;
    List<Map<String, dynamic>> responses = [];

    for (int i = 0; i < currentTest.questions.length; i++) {
      final q = currentTest.questions[i];
      final ansIdx = state.selectedAnswers[i];
      final isCorrect = ansIdx != null && q.options.isNotEmpty && ansIdx < q.options.length && q.options[ansIdx] == q.correctAnswer;
      
      if (isCorrect) totalScore += q.points;
      
      final tSpent = state.timeSpentPerQuestion[i] ?? 0;
      totalTime += tSpent;
      
      responses.add({
         'question_id': q.id,
         'is_correct': isCorrect,
         'time_spent_seconds': tSpent,
      });
    }

    final payload = {
      'test_id': currentTest.id,
      'total_score': totalScore,
      'time_taken_seconds': totalTime,
      'question_responses': responses,
    };
    
    try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.post('/users/me/test-attempts', data: payload);
        
        Map<String, dynamic>? report;
        if (response.data['ai_report'] != null) {
            report = Map<String, dynamic>.from(response.data['ai_report']);
        }
        
        state = state.copyWith(isFinished: true, isLoading: false, aiReport: report);
        
        // Save the full payload so it's available for the report immediately
        final fullAttempt = Map<String, dynamic>.from(payload);
        if (report != null) fullAttempt['ai_report'] = report;
        
        ref.read(completedTestsProvider.notifier).saveLocalScore(currentTest.id, totalScore, fullAttempt: fullAttempt);
    } catch (e) {
        debugPrint('Submit test failed: $e');
        state = state.copyWith(isFinished: true, isLoading: false);
    }
  }

  int get score {
    if (state.test == null) return 0;
    int s = 0;
    for (int i = 0; i < state.test!.questions.length; i++) {
      final q = state.test!.questions[i];
      final selected = state.selectedAnswers[i];
      if (selected != null && q.options.isNotEmpty && selected < q.options.length && q.options[selected] == q.correctAnswer) {
        s += q.points;
      }
    }
    return s;
  }
}

class CompletedTestsNotifier extends AsyncNotifier<Map<String, Map<String, dynamic>>> {
  @override
  Future<Map<String, Map<String, dynamic>>> build() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.get('/users/me/test-attempts');
      final Map<String, Map<String, dynamic>> attempts = {};
      for (var item in response.data) {
        final String testId = item['test_id'];
        final int score = (item['total_score'] as num?)?.toInt() ?? (item['score'] as num?)?.toInt() ?? 0;
        final int existingScore = attempts.containsKey(testId) ? ((attempts[testId]!['total_score'] as num?)?.toInt() ?? (attempts[testId]!['score'] as num?)?.toInt() ?? 0) : -1;
        
        if (!attempts.containsKey(testId) || score > existingScore) {
          attempts[testId] = item;
        }
      }
      return attempts;
    } catch (e) {
      return {};
    }
  }

  void saveLocalScore(String testId, int score, {Map<String, dynamic>? fullAttempt}) {
      final current = state.value ?? {};
      final updated = Map<String, Map<String, dynamic>>.from(current);
      final existingScore = updated.containsKey(testId) ? ((updated[testId]!['total_score'] as num?)?.toInt() ?? (updated[testId]!['score'] as num?)?.toInt() ?? 0) : -1;
      
      if (!updated.containsKey(testId) || score > existingScore) {
        updated[testId] = fullAttempt ?? {'test_id': testId, 'total_score': score};
      }
      state = AsyncValue.data(updated);
  }
}

final completedTestsProvider = AsyncNotifierProvider<CompletedTestsNotifier, Map<String, Map<String, dynamic>>>(() {
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
