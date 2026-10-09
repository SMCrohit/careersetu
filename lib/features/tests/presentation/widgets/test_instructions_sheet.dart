import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../domain/test_model.dart';
import 'test_card.dart';

/// Pre-test instructions in the Profile bottom-sheet style. Pops with `true` to start.
class TestInstructionsSheet extends StatelessWidget {
  final TestSummary test;
  final bool isRetake;

  const TestInstructionsSheet({super.key, required this.test, this.isRetake = false});

  static Future<bool> show(BuildContext context, TestSummary test, {bool isRetake = false}) async {
    final start = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TestInstructionsSheet(test: test, isRetake: isRetake),
    );
    return start == true;
  }

  @override
  Widget build(BuildContext context) {
    final rules = <(IconData, String)>[
      if (test.isPerQuestion)
        (Icons.hourglass_bottom_rounded, 'Each question has its own timer. When it runs out, you move to the next one. You can\'t go back.')
      else
        (Icons.timer_outlined, 'You have ${test.durationMins} minutes in total. You can move between questions freely.'),
      (Icons.quiz_outlined, '${test.questionCount} questions. Some may have more than one correct answer.'),
      if (test.negativeMarking) (Icons.remove_circle_outline, 'Wrong answers lose marks. Skip a question if you\'re unsure.'),
      if (test.passPercentage > 0) (Icons.flag_outlined, 'Score ${test.passPercentage}% or more to pass.'),
      (Icons.send_rounded, 'The test submits automatically when time is up.'),
      if (isRetake) (Icons.info_outline, 'This retake is for practice. No new discounts or offers are unlocked.'),
    ];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        gradient: AppUi.backgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isRetake ? 'Retake test' : 'Before you start',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
                    const SizedBox(height: 4),
                    Text(test.title, style: AppText.subtitle),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppUi.card(),
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 12,
                        children: [
                          TestFact(icon: Icons.timer_outlined, label: 'Duration', value: test.durationLabel),
                          TestFact(icon: Icons.quiz_outlined, label: 'Questions', value: '${test.questionCount}'),
                          if (test.totalMarks > 0)
                            TestFact(icon: Icons.star_outline_rounded, label: 'Marks', value: test.totalMarks.toStringAsFixed(test.totalMarks % 1 == 0 ? 0 : 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('How it works', style: AppText.sectionTitle),
                    const SizedBox(height: 10),
                    ...rules.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TestIconTile(icon: r.$1, size: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(r.$2, style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.secondaryText)),
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (test.instructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Instructions', style: AppText.sectionTitle),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: AppUi.card(),
                        child: Text(test.instructions, style: AppText.body),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: PrimaryButton(text: isRetake ? 'Start retake' : 'Start test', onPressed: () => Navigator.pop(context, true)),
            ),
          ],
        ),
      ),
    );
  }
}
