import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../domain/test_model.dart';
import 'test_card.dart';

/// Circular score ring, used on cards and the results hero.
class ScoreRing extends StatelessWidget {
  final double percentage;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;
  final TextStyle? textStyle;

  const ScoreRing({
    super.key,
    required this.percentage,
    this.size = 56,
    this.stroke = 6,
    this.color = AppUi.accent,
    this.trackColor = const Color(0xFFE2E8F0),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              strokeWidth: stroke,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text('${percentage.round()}%', style: textStyle ?? AppText.value.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

/// A test the user has taken, in My Tests.
class AttemptCard extends StatelessWidget {
  final TestSummary test;
  final VoidCallback onViewResult;
  final VoidCallback? onRetake;

  const AttemptCard({super.key, required this.test, required this.onViewResult, this.onRetake});

  @override
  Widget build(BuildContext context) {
    final best = test.bestAttempt;
    final passed = best?.isPassed ?? false;
    final passColor = passed ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final date = test.lastAttemptedAt ?? best?.completedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScoreRing(percentage: best?.percentage ?? 0, color: passed ? const Color(0xFF10B981) : AppUi.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(test.title, style: AppText.cardTitle),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (best?.maxScore != null) 'Best ${_num(best!.totalScore)} / ${_num(best.maxScore!)}',
                        '${test.attemptsUsed} ${test.attemptsUsed == 1 ? 'attempt' : 'attempts'}',
                      ].join('  ·  '),
                      style: AppText.label,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (best?.isPassed != null)
                          TestChip(label: passed ? 'Passed' : 'Not passed', color: passColor, icon: passed ? Icons.check_circle : Icons.cancel),
                        if (date != null) TestChip(label: DateFormat('d MMM yyyy').format(date.toLocal()), color: AppColors.secondaryText, icon: Icons.event),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SecondaryButton(text: 'View result', fontSize: 14, onPressed: best == null ? null : onViewResult)),
              if (onRetake != null) ...[
                const SizedBox(width: 10),
                Expanded(child: PrimaryButton(text: 'Retake', onPressed: onRetake)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
