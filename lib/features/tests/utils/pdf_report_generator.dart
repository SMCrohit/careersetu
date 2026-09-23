import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../presentation/providers/tests_provider.dart';
import 'package:intl/intl.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateTestReport({
    required ActiveTestState state,
    required String userName,
    required int score,
    required int attempted,
    required int accuracy,
  }) async {
    final pdf = pw.Document();

    final test = state.test;
    if (test == null) return Uint8List(0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Career Setu', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text(DateFormat('MMM d, yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Title and Student Info
            pw.Center(
              child: pw.Text(
                'Test Report: ${test.title}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text('Candidate: $userName', style: const pw.TextStyle(fontSize: 14)),
            ),
            pw.SizedBox(height: 30),

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem('Score', '$score / ${test.questions.length}'),
                  _buildSummaryItem('Attempted', '$attempted'),
                  _buildSummaryItem('Accuracy', '$accuracy%'),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Detailed Review Title
            pw.Text('Detailed Question Review', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),

            // Questions
            ...List.generate(test.questions.length, (index) {
              final q = test.questions[index];
              final selected = state.selectedAnswers[index];
              final isCorrect = selected == q.correctAnswerIndex;
              final isAttempted = selected != null;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Q${index + 1}. ${q.text}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Correct Answer: ${q.options[q.correctAnswerIndex]}', style: const pw.TextStyle(color: PdfColors.green700)),
                    if (isAttempted)
                      pw.Text(
                        'Your Answer: ${q.options[selected!]}',
                        style: pw.TextStyle(color: isCorrect ? PdfColors.green700 : PdfColors.red700),
                      )
                    else
                      pw.Text('Your Answer: Not Attempted', style: const pw.TextStyle(color: PdfColors.grey600)),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
