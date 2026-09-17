import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../providers/tests_provider.dart';

class TestResultsScreen extends ConsumerWidget {
  const TestResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeTestProvider);
    final correct = ref.read(activeTestProvider.notifier).score;
    final total = state.test?.questions.length ?? 0;
    
    final attempted = state.selectedAnswers.length;
    final incorrect = attempted - correct;
    final accuracy = attempted > 0 ? (correct / attempted * 100).toInt() : 0;
    final totalScore = correct;
    final maxScore = total;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 1,
        title: const Text('Test Results', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Text(state.test?.title ?? 'Test Results', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryText), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBrand, width: 8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$totalScore', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        Text('/ $maxScore', style: const TextStyle(fontSize: 16, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            
            // Performance Summary
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Performance Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDashTile('Attempted', '$attempted / $total')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDashTile('Accuracy', '$accuracy%', color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashTile(
                          'Correct', 
                          '$correct', 
                          color: AppColors.success,
                          onTap: () => _showReviewSheet(context, state, true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDashTile(
                          'Incorrect', 
                          '$incorrect', 
                          color: AppColors.error,
                          onTap: () => _showReviewSheet(context, state, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('Tap Correct/Incorrect cards to review answers.', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PrimaryButton(
                text: 'Back to Home',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, ActiveTestState state, bool isCorrectReview) {
    if (state.test == null) return;
    
    final questions = state.test!.questions;
    final filteredIndices = <int>[];
    
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selected = state.selectedAnswers[i];
      
      if (isCorrectReview) {
        if (selected == q.correctAnswerIndex) {
          filteredIndices.add(i);
        }
      } else {
        // Incorrect means selected is wrong, or unattempted
        if (selected != q.correctAnswerIndex) {
          filteredIndices.add(i);
        }
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isCorrectReview ? 'Correct Answers' : 'Incorrect Answers', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredIndices.isEmpty 
                    ? const Center(child: Text("No questions to display.", style: TextStyle(color: AppColors.secondaryText)))
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredIndices.length,
                        itemBuilder: (context, index) {
                          final qIndex = filteredIndices[index];
                          final q = questions[qIndex];
                          final selected = state.selectedAnswers[qIndex];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Q${qIndex + 1}. ${q.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 12),
                                ...List.generate(q.options.length, (optIndex) {
                                  final isSelected = selected == optIndex;
                                  final isCorrect = q.correctAnswerIndex == optIndex;
                                  
                                  Color bgColor = AppColors.white;
                                  Color borderColor = AppColors.border;
                                  IconData? icon;
                                  Color iconColor = Colors.transparent;
                                  
                                  if (isCorrect) {
                                    bgColor = const Color(0xFFF0FDF4); // Light green
                                    borderColor = AppColors.success;
                                    icon = Icons.check_circle;
                                    iconColor = AppColors.success;
                                  } else if (isSelected && !isCorrect) {
                                    bgColor = const Color(0xFFFEF2F2); // Light red
                                    borderColor = AppColors.error;
                                    icon = Icons.cancel;
                                    iconColor = AppColors.error;
                                  }
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      border: Border.all(color: borderColor),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        if (icon != null) ...[
                                          Icon(icon, color: iconColor, size: 20),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(child: Text(q.options[optIndex])),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDashTile(String title, String value, {Color color = AppColors.primaryText, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
