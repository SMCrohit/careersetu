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
    
    final totalQ = test.questions.length;
    final incorrect = attempted - score;
    final unattempted = totalQ - attempted;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey200, width: 2))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CAREER SETU', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 4),
                      pw.Text('Comprehensive Performance Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(DateFormat('MMMM d, yyyy').format(DateTime.now()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      pw.SizedBox(height: 4),
                      pw.Text('Candidate: $userName', style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey800)),
                    ]
                  )
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            
            // Title
            pw.Text(test.title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            if (test.description.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(test.description, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ],
            pw.SizedBox(height: 24),

            // Score Dashboard
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
                  _buildStatCard('Score', '$score / $totalQ', PdfColors.blue800),
                  _buildStatCard('Accuracy', '$accuracy%', PdfColors.green700),
                  _buildStatCard('Attempted', '$attempted / $totalQ', PdfColors.orange700),
                  _buildStatCard('Incorrect', '$incorrect', PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // AI Performance Analysis
            if (state.aiReport != null) ...[
              pw.Text('AI Performance Analysis', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (state.aiReport!['mastered_topics'] != null && (state.aiReport!['mastered_topics'] as List).isNotEmpty) ...[
                      pw.Text('Mastered Topics', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.SizedBox(height: 4),
                      pw.Text((state.aiReport!['mastered_topics'] as List).join(', '), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                      pw.SizedBox(height: 12),
                    ],
                    if (state.aiReport!['weak_topics'] != null && (state.aiReport!['weak_topics'] as List).isNotEmpty) ...[
                      pw.Text('Topics to Improve', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                      pw.SizedBox(height: 4),
                      pw.Text((state.aiReport!['weak_topics'] as List).join(', '), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                      pw.SizedBox(height: 12),
                    ],
                    if (state.aiReport!['recommendations'] != null) ...[
                      pw.Text('Recommendation', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                      pw.SizedBox(height: 4),
                      pw.Text(state.aiReport!['recommendations'].toString(), style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5, color: PdfColors.black)),
                    ],
                  ]
                )
              ),
              pw.SizedBox(height: 32),
            ],


          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor valueColor) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey600)),
        pw.SizedBox(height: 8),
        pw.Text(value, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
