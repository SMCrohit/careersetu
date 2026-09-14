import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../providers/tests_provider.dart';
import 'test_results_screen.dart';

class ActiveTestScreen extends ConsumerWidget {
  const ActiveTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeTestProvider);

    if (state.isLoading || state.test == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TestResultsScreen()));
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = state.test!.questions[state.currentQuestionIndex];
    final selectedAnswerIndex = state.selectedAnswers[state.currentQuestionIndex];

    final minutesStr = (state.timeRemaining / 60).floor().toString().padLeft(2, '0');
    final secondsStr = (state.timeRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Question ${state.currentQuestionIndex + 1}/${state.test!.questions.length}', style: const TextStyle(fontSize: 16)),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '$minutesStr:$secondsStr',
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (state.currentQuestionIndex + 1) / state.test!.questions.length,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBrand),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(question.options.length, (index) {
                    final isSelected = selectedAnswerIndex == index;
                    return GestureDetector(
                      onTap: () {
                        ref.read(activeTestProvider.notifier).selectAnswer(index);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F0FE) : AppColors.white,
                          border: Border.all(color: isSelected ? AppColors.primaryBrand : AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryBrand : AppColors.secondaryText,
                                  width: 2,
                                ),
                              ),
                              child: isSelected 
                                  ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.primaryBrand, shape: BoxShape.circle))) 
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(question.options[index], style: const TextStyle(fontSize: 16, color: AppColors.primaryText))),
                          ],
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                if (state.currentQuestionIndex > 0)
                  Expanded(
                    child: SecondaryButton(
                      text: 'Previous',
                      onPressed: () => ref.read(activeTestProvider.notifier).previousQuestion(),
                    ),
                  ),
                if (state.currentQuestionIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: state.currentQuestionIndex == state.test!.questions.length - 1 ? 'Submit' : 'Next',
                    onPressed: () {
                      if (state.currentQuestionIndex == state.test!.questions.length - 1) {
                        ref.read(activeTestProvider.notifier).submitTest();
                      } else {
                        ref.read(activeTestProvider.notifier).nextQuestion();
                      }
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
