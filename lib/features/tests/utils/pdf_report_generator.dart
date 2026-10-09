import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/test_model.dart';

/// PDF report for a graded attempt, built from the server's result.
class PdfReportGenerator {
  static Future<Uint8List> generateTestReport({required AttemptResult result, required String userName}) async {
    final pdf = pw.Document();
    final report = result.aiReport;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 20),
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey200, width: 2))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('CAREER SETU', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.SizedBox(height: 4),
                  pw.Text('Performance Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text(DateFormat('MMMM d, yyyy').format((result.completedAt ?? DateTime.now()).toLocal()),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  pw.SizedBox(height: 4),
                  pw.Text('Candidate: $userName', style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey800)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(result.testTitle, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(
            '${result.isPassed ? 'Passed' : 'Not passed'}${result.passPercentage != null ? ' (pass mark ${result.passPercentage}%)' : ''}'
            '  ·  Time taken ${result.timeLabel}${result.attemptNumber > 1 ? '  ·  Attempt ${result.attemptNumber}' : ''}',
            style: pw.TextStyle(fontSize: 12, color: result.isPassed ? PdfColors.green700 : PdfColors.red700),
          ),
          pw.SizedBox(height: 20),

          // Score dashboard
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: PdfColors.blue200, width: 1.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _stat('Score', result.scoreLabel, PdfColors.blue800),
                _stat('Percentage', '${result.percentage.toStringAsFixed(1)}%', PdfColors.indigo700),
                _stat('Accuracy', '${result.accuracy}%', PdfColors.green700),
                _stat('Correct', '${result.correct}', PdfColors.green800),
                _stat('Wrong', '${result.incorrect}', PdfColors.red700),
                _stat('Skipped', '${result.skipped}', PdfColors.orange700),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          if (result.topicScores.isNotEmpty) ...[
            _heading('Topic-wise performance'),
            pw.TableHelper.fromTextArray(
              headers: ['Topic', 'Correct', 'Accuracy'],
              data: result.topicScores.map((t) => [t.label, '${t.correct} / ${t.total}', '${t.accuracy}%']).toList(),
              headerStyle: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.center},
            ),
            pw.SizedBox(height: 24),
          ],

          if (report != null) ...[
            _heading('AI Performance Summary'),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                if (report.overallInsight.isNotEmpty) ...[
                  pw.Text(report.overallInsight, style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
                  pw.SizedBox(height: 12),
                ],
                if (report.strongAreas.isNotEmpty) ...[
                  _label('Strengths', PdfColors.green800),
                  pw.Text(report.strongAreas.map((a) => '${a.label} (${a.accuracy}%)').join(', '), style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 10),
                ],
                if (report.weakAreas.isNotEmpty) ...[
                  _label('Needs work', PdfColors.red800),
                  pw.Text(report.weakAreas.map((a) => '${a.label} (${a.accuracy}%)').join(', '), style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 10),
                ],
                if (report.timeManagement.isNotEmpty) ...[
                  _label('Time management', PdfColors.blueGrey800),
                  pw.Text(report.timeManagement, style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 10),
                ],
                if (report.nextSteps.isNotEmpty) ...[
                  _label('Next steps', PdfColors.blue800),
                  ...report.nextSteps.map(_bullet),
                ],
              ]),
            ),
            pw.SizedBox(height: 24),
          ],

          if (result.reviewAvailable && result.responses.isNotEmpty) ...[
            _heading('Answer review'),
            ...result.responses.asMap().entries.map((e) => _review(e.key, e.value)),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _review(int index, QuestionReview q) {
    String texts(List<String> ids, String fallback) {
      final byId = {for (final o in q.options) o.id: o.text};
      final values = ids.map((id) => byId[id] ?? id).where((t) => t.isNotEmpty).toList();
      return values.isNotEmpty ? values.join(', ') : fallback;
    }

    final status = q.isSkipped ? 'Skipped' : (q.isCorrect ? 'Correct' : 'Wrong');
    final color = q.isSkipped ? PdfColors.orange700 : (q.isCorrect ? PdfColors.green700 : PdfColors.red700);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Text('Q${index + 1}. ${q.text}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(width: 8),
          pw.Text(status, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
        ]),
        pw.SizedBox(height: 4),
        pw.Text('Your answer: ${texts(q.selectedIds, q.selectedText.isNotEmpty ? q.selectedText : '—')}', style: const pw.TextStyle(fontSize: 10)),
        if (q.hasAnswerKey) pw.Text('Correct answer: ${texts(q.correctIds, q.correctText)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green800)),
        if (q.explanation.isNotEmpty) pw.Text('Why: ${q.explanation}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ]),
    );
  }

  static pw.Widget _heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
      );

  static pw.Widget _label(String text, PdfColor color) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
      );

  // Drawn dot: the default PDF font has no bullet character.
  static pw.Widget _bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 5, right: 6),
            width: 3,
            height: 3,
            decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 12))),
        ]),
      );

  static pw.Widget _stat(String label, String value, PdfColor color) => pw.Column(children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey600)),
        pw.SizedBox(height: 6),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ]);
}
