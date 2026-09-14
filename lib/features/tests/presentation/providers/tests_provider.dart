import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/tests_repository.dart';
import '../../domain/test_model.dart';

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
    state = state.copyWith(isFinished: true);
    
    // Save to completed tests if a test is loaded
    if (state.test != null) {
      ref.read(completedTestsProvider.notifier).saveScore(state.test!.id, score);
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

class CompletedTestsNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    return {};
  }

  void saveScore(String testId, int score) {
    // Only save the highest score
    final currentBest = state[testId] ?? -1;
    if (score > currentBest) {
      state = {...state, testId: score};
    }
  }
}

final completedTestsProvider = NotifierProvider<CompletedTestsNotifier, Map<String, int>>(() {
  return CompletedTestsNotifier();
});

final activeTestProvider = NotifierProvider<ActiveTestNotifier, ActiveTestState>(() {
  return ActiveTestNotifier();
});

final allTestsProvider = FutureProvider<List<TestModel>>((ref) async {
  final repo = ref.read(testsRepositoryProvider);
  return repo.fetchAllTests();
});
