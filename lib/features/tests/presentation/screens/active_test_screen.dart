import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../domain/test_model.dart';
import '../providers/tests_provider.dart';
import '../widgets/test_card.dart';
import '../widgets/test_instructions_sheet.dart';
import 'test_results_screen.dart';

/// Shows the instructions, then opens the exam. Used by the Tests tab and My Tests (retake).
Future<void> startTestFlow(BuildContext context, WidgetRef ref, TestSummary test, {bool isRetake = false}) async {
  final start = await TestInstructionsSheet.show(context, test, isRetake: isRetake);
  if (!start || !context.mounted) return;
  ref.read(examProvider.notifier).start(test.id);
  await Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTestScreen()));
}

/// Taking a test, one question at a time.
class ActiveTestScreen extends ConsumerWidget {
  const ActiveTestScreen({super.key});

  Future<bool> _confirm(BuildContext context, {required String title, required String message, required String action, bool danger = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppText.screenTitle),
        content: Text(message, style: AppText.subtitle),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(child: SecondaryButton(text: 'Cancel', height: 44, fontSize: 14, onPressed: () => Navigator.pop(context, false))),
              const SizedBox(width: 10),
              Expanded(
                child: danger
                    ? SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      )
                    : PrimaryButton(text: action, onPressed: () => Navigator.pop(context, true)),
              ),
            ],
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final state = ref.read(examProvider);
    if (state.test == null || state.result != null) {
      ref.read(examProvider.notifier).reset();
      Navigator.pop(context);
      return;
    }
    final leave = await _confirm(context,
        title: 'Leave test?', message: 'Your answers will be lost and this attempt won\'t be saved.', action: 'Leave', danger: true);
    if (leave && context.mounted) {
      ref.read(examProvider.notifier).reset();
      Navigator.pop(context);
    }
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final state = ref.read(examProvider);
    final unanswered = state.total - state.answeredCount;
    final ok = await _confirm(
      context,
      title: 'Submit test?',
      message: unanswered > 0
          ? 'You have $unanswered unanswered ${unanswered == 1 ? 'question' : 'questions'}. You can\'t change answers after submitting.'
          : 'You\'ve answered every question. You can\'t change answers after submitting.',
      action: 'Submit',
    );
    if (ok) ref.read(examProvider.notifier).submit();
  }

  void _openPalette(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(builder: (context, ref, _) {
        final state = ref.watch(examProvider);
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(height: 16),
                const Text('All questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
                const SizedBox(height: 4),
                Text('${state.answeredCount} of ${state.total} answered', style: AppText.label),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < state.total; i++)
                      GestureDetector(
                        onTap: () {
                          ref.read(examProvider.notifier).jumpTo(i);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: state.isAnswered(state.test!.questions[i].id) ? AppUi.accentGradient : null,
                            color: state.isAnswered(state.test!.questions[i].id) ? null : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: i == state.index ? AppUi.ink : const Color(0xFFCBD5E1), width: i == state.index ? 2 : 1),
                          ),
                          child: Text('${i + 1}',
                              style: AppText.value.copyWith(
                                  fontSize: 13, color: state.isAnswered(state.test!.questions[i].id) ? Colors.white : AppColors.primaryText)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examProvider);

    // Go to results once graded.
    ref.listen(examProvider.select((s) => s.result), (_, result) {
      if (result != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestResultsScreen(result: result)));
        ref.read(examProvider.notifier).reset();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !state.isSubmitting) _leave(context, ref);
      },
      child: Container(
        decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.primaryText), onPressed: state.isSubmitting ? null : () => _leave(context, ref)),
            title: Text(state.test?.info.title ?? 'Test', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.screenTitle.copyWith(fontSize: 16)),
            actions: [
              if (state.question != null) ...[_timerPill(state), const SizedBox(width: 16)],
            ],
          ),
          body: Stack(
            children: [
              _body(context, ref, state),
              if (state.isSubmitting) _submittingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, ExamState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppUi.accent));
    }
    final question = state.question;
    if (question == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(state.error ?? 'Could not load the test.', textAlign: TextAlign.center, style: AppText.subtitle),
              const SizedBox(height: 20),
              SecondaryButton(text: 'Go back', width: 180, onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      );
    }

    final selected = state.answers[question.id] ?? const <String>{};
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Question ${state.index + 1} of ${state.total}', style: AppText.value),
                  const Spacer(),
                  if (!state.isPerQuestion)
                    TextButton.icon(
                      onPressed: () => _openPalette(context, ref),
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: Text('${state.answeredCount}/${state.total} answered'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primaryBrand, visualDensity: VisualDensity.compact),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(height: 6, color: const Color(0xFFE2E8F0)),
                    FractionallySizedBox(
                      widthFactor: (state.index + 1) / state.total,
                      child: Container(height: 6, decoration: const BoxDecoration(gradient: AppUi.accentGradient)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppUi.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        TestChip(label: question.topic, icon: Icons.bookmark_outline),
                        TestChip(
                          label: '${_marks(question.marks)} ${question.marks == 1 ? 'mark' : 'marks'}'
                              '${question.negativeMarks > 0 ? '  ·  −${_marks(question.negativeMarks)} if wrong' : ''}',
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(question.text, style: AppText.cardTitle.copyWith(fontSize: 16, height: 1.45)),
                    if (question.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(question.imageUrl, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    ],
                    if (question.note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(question.note, style: AppText.label.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (question.isMulti)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text('Select all that apply', style: AppText.label.copyWith(color: AppColors.primaryBrand, fontWeight: FontWeight.w600)),
                ),
              ...question.options.asMap().entries.map((e) => _optionCard(
                    ref,
                    letter: String.fromCharCode(65 + e.key),
                    option: e.value,
                    isSelected: selected.contains(e.value.id),
                    isMulti: question.isMulti,
                  )),
              if (state.error != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                  child: Text(state.error!, style: AppText.label.copyWith(color: AppColors.error)),
                ),
            ],
          ),
        ),
        _bottomBar(context, ref, state),
      ],
    );
  }

  Widget _optionCard(WidgetRef ref, {required String letter, required TestOption option, required bool isSelected, required bool isMulti}) {
    return GestureDetector(
      onTap: () => ref.read(examProvider.notifier).toggleOption(option.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF8FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppUi.accent : Colors.transparent, width: 1.5),
          boxShadow: AppUi.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected ? AppUi.accentGradient : null,
                color: isSelected ? null : AppUi.iconTile,
                shape: isMulti ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isMulti ? BorderRadius.circular(8) : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : Text(letter, style: AppText.value.copyWith(fontSize: 13, color: AppUi.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(option.text, style: AppText.body.copyWith(fontSize: 14.5))),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, WidgetRef ref, ExamState state) {
    final canGoBack = !state.isPerQuestion && state.index > 0;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            if (canGoBack) ...[
              Expanded(child: SecondaryButton(text: 'Previous', onPressed: state.isSubmitting ? null : ref.read(examProvider.notifier).previous)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: PrimaryButton(
                text: state.isLast ? (state.error != null ? 'Retry submit' : 'Submit') : 'Next',
                onPressed: state.isSubmitting ? null : (state.isLast ? () => _submit(context, ref) : ref.read(examProvider.notifier).next),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerPill(ExamState state) {
    final low = state.timeLeft <= (state.isPerQuestion ? 10 : 60);
    final m = (state.timeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (state.timeLeft % 60).toString().padLeft(2, '0');
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: low ? const Color(0xFFFEE2E2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppUi.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: low ? AppColors.error : AppUi.accent),
            const SizedBox(width: 4),
            Text('$m:$s', style: AppText.value.copyWith(color: low ? AppColors.error : AppColors.primaryText, fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }

  Widget _submittingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.85),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          const Text('Grading your test…', style: AppText.screenTitle),
          const SizedBox(height: 4),
          const Text('Preparing your AI summary', style: AppText.label),
          const SizedBox(height: 16),
          const SizedBox(width: 140, child: LinearProgressIndicator(color: AppUi.accent, backgroundColor: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }

  static String _marks(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
