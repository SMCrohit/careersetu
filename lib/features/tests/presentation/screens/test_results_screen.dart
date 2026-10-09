import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/test_model.dart';
import '../../utils/pdf_report_generator.dart';
import '../widgets/attempt_card.dart';
import '../widgets/test_card.dart';

/// Results of a graded attempt: a fresh submission or a past one from My Tests.
class TestResultsScreen extends ConsumerStatefulWidget {
  final AttemptResult result;

  const TestResultsScreen({super.key, required this.result});

  @override
  ConsumerState<TestResultsScreen> createState() => _TestResultsScreenState();
}

enum _ReviewFilter { all, correct, incorrect, skipped }

class _TestResultsScreenState extends ConsumerState<TestResultsScreen> {
  bool _downloading = false;

  AttemptResult get r => widget.result;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final name = ref.read(authProvider).currentUser?.fullName ?? 'Student';
      final bytes = await PdfReportGenerator.generateTestReport(result: r, userName: name);
      final path = await FileSaver.instance.saveFile(
        name: '${r.testTitle.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_Report',
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) CustomToast.showSuccess(context, 'Report downloaded');
      if (path.isNotEmpty) await OpenFilex.open(path);
    } catch (_) {
      if (mounted) CustomToast.showError(context, 'Could not download the report.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: const Text('Result', style: AppText.screenTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _hero(),
            const SizedBox(height: 14),
            _stats(),
            if (r.discountUnlocked > 0) ...[const SizedBox(height: 14), _discountBanner()],
            const SizedBox(height: 14),
            _aiSummary(),
            if (r.topicScores.length > 1 || r.sectionScores.length > 1) ...[const SizedBox(height: 14), _breakdown()],
            const SizedBox(height: 20),
            if (r.responses.isNotEmpty) ...[
              SecondaryButton(text: 'Review answers', onPressed: () => _openReview(_ReviewFilter.all)),
              const SizedBox(height: 12),
            ],
            PrimaryButton(text: _downloading ? 'Preparing report…' : 'Download report', onPressed: _downloading ? null : _download),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    final passColor = r.isPassed ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppUi.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          ScoreRing(
            percentage: r.percentage,
            size: 96,
            stroke: 9,
            color: Colors.white,
            trackColor: Colors.white24,
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.testTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.cardTitle.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('Score ${r.scoreLabel}', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _heroChip(r.isPassed ? Icons.check_circle : Icons.cancel, r.isPassed ? 'Passed' : 'Not passed', passColor),
                    _heroChip(Icons.timer_outlined, r.timeLabel, Colors.white),
                    if (r.attemptNumber > 1) _heroChip(Icons.replay_rounded, 'Attempt ${r.attemptNumber}', Colors.white),
                  ],
                ),
                if (r.passPercentage != null) ...[
                  const SizedBox(height: 8),
                  Text('Pass mark ${r.passPercentage}%', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppText.badge.copyWith(color: color)),
      ]),
    );
  }

  Widget _stats() {
    final tiles = [
      (Icons.check_circle_outline, 'Correct', '${r.correct}', const Color(0xFF059669), _ReviewFilter.correct),
      (Icons.highlight_off_rounded, 'Incorrect', '${r.incorrect}', AppColors.error, _ReviewFilter.incorrect),
      (Icons.remove_circle_outline, 'Skipped', '${r.skipped}', const Color(0xFFD97706), _ReviewFilter.skipped),
      (Icons.track_changes_rounded, 'Accuracy', '${r.accuracy}%', AppUi.accent, null),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: tiles.map((t) {
        return GestureDetector(
          onTap: t.$5 != null && r.responses.isNotEmpty ? () => _openReview(t.$5!) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: AppUi.card(),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: t.$4.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(t.$1, size: 20, color: t.$4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$2, style: AppText.label),
                      Text(t.$3, style: AppText.cardTitle.copyWith(fontSize: 18, color: t.$4)),
                    ],
                  ),
                ),
                if (t.$5 != null && r.responses.isNotEmpty) const Icon(Icons.chevron_right, size: 18, color: AppColors.borderDark),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _discountBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: Color(0xFF059669)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('You unlocked ${r.discountUnlocked}% off class fees!',
                style: AppText.value.copyWith(color: const Color(0xFF065F46))),
          ),
        ],
      ),
    );
  }

  Widget _aiSummary() {
    final report = r.aiReport;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('AI summary', style: AppText.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          if (report == null)
            Text('An AI summary isn\'t available for this attempt. Your scores and answer review are below.',
                style: AppText.subtitle.copyWith(height: 1.4))
          else ...[
            if (report.overallInsight.isNotEmpty) Text(report.overallInsight, style: AppText.body),
            if (report.strongAreas.isNotEmpty) ...[
              const SizedBox(height: 14),
              _areaGroup('Your strengths', Icons.trending_up_rounded, report.strongAreas, const Color(0xFF059669)),
            ],
            if (report.weakAreas.isNotEmpty) ...[
              const SizedBox(height: 14),
              _areaGroup('Needs work', Icons.trending_down_rounded, report.weakAreas, const Color(0xFFD97706)),
            ],
            if (report.timeManagement.isNotEmpty) ...[
              const SizedBox(height: 14),
              _infoRow(Icons.schedule_rounded, 'Time management', report.timeManagement),
            ],
            if (report.nextSteps.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Next steps', style: AppText.value.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              ...report.nextSteps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppUi.iconTile, shape: BoxShape.circle),
                          child: Text('${e.key + 1}', style: AppText.badge.copyWith(color: AppUi.accent)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value, style: AppText.body.copyWith(fontSize: 13.5))),
                      ],
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _areaGroup(String title, IconData icon, List<TopicScore> areas, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: AppText.value.copyWith(fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: areas.map((a) => TestChip(label: '${a.label} · ${a.accuracy}%', color: color)).toList(),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String title, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TestIconTile(icon: icon, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.value.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(text, style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.secondaryText)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _breakdown() {
    final useSections = r.sectionScores.length > 1;
    final rows = useSections
        ? r.sectionScores.map((s) => (s.section, s.total > 0 ? (s.correct / s.total * 100).round() : 0, '${s.correct}/${s.total}')).toList()
        : r.topicScores.map((t) => (t.label, t.accuracy, '${t.correct}/${t.total}')).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(useSections ? 'Section-wise' : 'Topic-wise', style: AppText.sectionTitle),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(row.$1, style: AppText.body.copyWith(fontSize: 13.5))),
                      Text('${row.$3}  ·  ${row.$2}%', style: AppText.label),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: row.$2 / 100,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation(row.$2 >= 70 ? const Color(0xFF10B981) : (row.$2 >= 50 ? AppUi.accent : const Color(0xFFF59E0B))),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _openReview(_ReviewFilter initial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(result: r, initial: initial),
    );
  }
}

/// Question-by-question review in the Profile bottom-sheet style.
class _ReviewSheet extends StatefulWidget {
  final AttemptResult result;
  final _ReviewFilter initial;

  const _ReviewSheet({required this.result, required this.initial});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late _ReviewFilter _filter = widget.initial;

  bool _matches(QuestionReview q) => switch (_filter) {
        _ReviewFilter.all => true,
        _ReviewFilter.correct => q.isCorrect,
        _ReviewFilter.incorrect => q.isAttempted && !q.isCorrect,
        _ReviewFilter.skipped => q.isSkipped,
      };

  @override
  Widget build(BuildContext context) {
    final all = widget.result.responses;
    final items = [for (var i = 0; i < all.length; i++) if (_matches(all[i])) (i, all[i])];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Answer review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink))),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: _ReviewFilter.values.map((f) {
                  final selected = f == _filter;
                  final label = '${f.name[0].toUpperCase()}${f.name.substring(1)}';
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: selected ? AppUi.accentGradient : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(label, style: AppText.chip.copyWith(fontSize: 13, color: selected ? Colors.white : AppColors.secondaryText)),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (!widget.result.reviewAvailable)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text('Correct answers will be shown later, as set by the test provider.',
                    style: AppText.label.copyWith(color: const Color(0xFFD97706))),
              ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No questions here', style: AppText.subtitle))
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _questionCard(items[i].$1, items[i].$2),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(int index, QuestionReview q) {
    final (statusLabel, statusColor) = q.isSkipped
        ? ('Skipped', const Color(0xFFD97706))
        : (q.isCorrect ? ('Correct', const Color(0xFF059669)) : ('Incorrect', AppColors.error));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppUi.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('Q${index + 1}. ${q.text}', style: AppText.cardTitle.copyWith(fontSize: 14.5))),
              const SizedBox(width: 8),
              TestChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          if (q.options.isNotEmpty)
            ...q.options.map((o) {
              final picked = q.selectedIds.contains(o.id);
              final right = q.correctIds.contains(o.id);
              final color = right ? const Color(0xFF059669) : (picked ? AppColors.error : null);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color?.withOpacity(0.07) ?? const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color?.withOpacity(0.6) ?? Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(
                      right ? Icons.check_circle_rounded : (picked ? Icons.cancel_rounded : Icons.radio_button_unchecked),
                      size: 18,
                      color: color ?? AppColors.borderDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(o.text, style: AppText.body.copyWith(fontSize: 13.5))),
                    if (picked) Text('Your answer', style: AppText.badge.copyWith(color: color ?? AppColors.secondaryText)),
                  ],
                ),
              );
            })
          else ...[
            // Older attempts stored answer text only.
            Text('Your answer: ${q.selectedText.isNotEmpty ? q.selectedText : '—'}', style: AppText.body.copyWith(fontSize: 13.5)),
            if (q.correctText.isNotEmpty)
              Text('Correct answer: ${q.correctText}', style: AppText.body.copyWith(fontSize: 13.5, color: const Color(0xFF059669))),
          ],
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppUi.softBlue, borderRadius: BorderRadius.circular(10)),
              child: Text('💡 ${q.explanation}', style: AppText.label.copyWith(color: AppColors.primaryText, height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}
