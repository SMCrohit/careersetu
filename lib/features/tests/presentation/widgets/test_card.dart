import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../domain/test_model.dart';

/// Icon on the light-blue tile used by Profile rows.
class TestIconTile extends StatelessWidget {
  final IconData icon;
  final double size;

  const TestIconTile({super.key, required this.icon, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppUi.iconTile, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: size, color: AppUi.accent),
    );
  }
}

/// Small rounded label.
class TestChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;

  const TestChip({super.key, required this.label, this.color = AppColors.primaryBrand, this.background, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background ?? color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: AppText.badge.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Fact with an icon tile, e.g. "10 min".
class TestFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const TestFact({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TestIconTile(icon: icon, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.label),
            Text(value, style: AppText.value.copyWith(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

/// An active test in the Tests tab.
class TestCard extends StatelessWidget {
  final TestSummary test;
  final VoidCallback onStart;

  const TestCard({super.key, required this.test, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final ends = test.endsLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TestChip(label: test.tag.isNotEmpty ? test.tag : 'Skill test', icon: Icons.label_outline),
              if (test.isNew) const TestChip(label: 'New', color: Color(0xFF0284C7), icon: Icons.fiber_new_rounded),
              if (ends != null) TestChip(label: ends, color: const Color(0xFFDC2626), icon: Icons.schedule_rounded),
              if (test.maxDiscountPercentage > 0)
                TestChip(
                  label: 'Up to ${test.maxDiscountPercentage}% off class fees',
                  color: const Color(0xFFC2410C),
                  icon: Icons.local_offer_outlined,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(test.title, style: AppText.cardTitle),
          if (test.providerName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('by ${test.providerName}', style: AppText.label.copyWith(color: AppColors.primaryBrand)),
          ],
          if (test.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(test.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.subtitle),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              TestFact(icon: Icons.timer_outlined, label: 'Duration', value: test.durationLabel),
              TestFact(icon: Icons.quiz_outlined, label: 'Questions', value: '${test.questionCount}'),
              TestFact(icon: Icons.speed_rounded, label: 'Level', value: test.difficulty),
            ],
          ),
          if (test.negativeMarking || test.passPercentage > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (test.passPercentage > 0) TestChip(label: 'Pass ${test.passPercentage}%', color: const Color(0xFF059669)),
                if (test.negativeMarking) const TestChip(label: 'Negative marking', color: Color(0xFFDC2626)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(text: 'Start test', onPressed: onStart),
        ],
      ),
    );
  }
}

/// Grey placeholder while tests load.
class TestCardSkeleton extends StatelessWidget {
  const TestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h, [double r = 6]) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(r)));
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(90, 20, 20),
          const SizedBox(height: 14),
          bar(200, 16),
          const SizedBox(height: 8),
          bar(double.infinity, 12),
          const SizedBox(height: 16),
          Row(children: [bar(80, 34), const SizedBox(width: 12), bar(80, 34), const SizedBox(width: 12), bar(80, 34)]),
          const SizedBox(height: 16),
          bar(double.infinity, 48, 24),
        ],
      ),
    );
  }
}
