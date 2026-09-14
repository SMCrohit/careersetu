import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../domain/test_model.dart';
import '../providers/tests_provider.dart';
import 'active_test_screen.dart';

class MyTestsScreen extends ConsumerWidget {
  const MyTestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(allTestsProvider);
    final completedTests = ref.watch(completedTestsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Tests', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryBrand),
      ),
      body: testsAsync.when(
        data: (tests) {
          final myAttempts = tests.where((t) => completedTests.containsKey(t.id)).toList();
          
          if (myAttempts.isEmpty) return const Center(child: Text("You haven't taken any tests yet."));
          
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            itemCount: myAttempts.length,
            itemBuilder: (context, index) {
              final test = myAttempts[index];
              return _buildTestCard(
                context: context,
                ref: ref,
                test: test,
                isCompleted: true,
                score: completedTests[test.id],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTestCard({
    required BuildContext context, 
    required WidgetRef ref, 
    required TestModel test, 
    required bool isCompleted, 
    int? score
  }) {
    // Determine the discount unlocked if completed
    int discountUnlocked = 0;
    if (isCompleted && score != null) {
      double percentage = score / test.questions.length;
      if (percentage >= 0.8) {
        discountUnlocked = test.maxDiscountPercentage;
      } else if (percentage >= 0.5) {
        discountUnlocked = (test.maxDiscountPercentage / 2).floor();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  test.tag.isNotEmpty ? test.tag : 'Skill Assessment', 
                  style: const TextStyle(color: AppColors.primaryBrand, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(test.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          const SizedBox(height: 4),
          Text('Provided by: ${test.providerName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
          const SizedBox(height: 8),
          Text(test.description, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(Icons.timer, '${test.durationMins} Mins'),
              _buildInfoItem(Icons.list_alt, '${test.questions.length} Questions'),
              _buildInfoItem(Icons.star, test.difficulty),
            ],
          ),
          
          if (isCompleted) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Score', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    Text('$score / ${test.questions.length}', style: const TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (discountUnlocked > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Discount Unlocked!', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('$discountUnlocked% OFF', style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                if (discountUnlocked == 0 && test.maxDiscountPercentage > 0)
                  const Text('Keep practicing to\nunlock discounts!', style: TextStyle(color: AppColors.secondaryText, fontSize: 12), textAlign: TextAlign.right),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Retaking this test is for practice only. No additional offers or discounts will be unlocked on retest.',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          PrimaryButton(
            text: isCompleted ? 'Retest (Practice Only)' : 'Start Test',
            onPressed: () {
              ref.read(activeTestProvider.notifier).loadTest(test.id);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTestScreen()));
            },
          )
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}