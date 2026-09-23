import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate4Minimalist({
  required String name,
  required String email,
  required String phone,
  required String city,
  required String goal,
  required String summary,
  required List<Map<String, dynamic>> experience,
  required List<Map<String, dynamic>> education,
  required List<String> skills,
  required List<Map<String, dynamic>> projects,
  required PdfColor primaryColor,
  pw.MemoryImage? profileImage,
}) {
  return [
    pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (profileImage != null)
            pw.Container(
              width: 80,
              height: 80,
              margin: const pw.EdgeInsets.only(bottom: 15),
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
              ),
            ),
          pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
          pw.SizedBox(height: 4),
          pw.Text(goal.toUpperCase(), style: pw.TextStyle(fontSize: 12, color: primaryColor, letterSpacing: 1)),
          pw.SizedBox(height: 8),
          pw.Text('$email   •   $phone   •   $city', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    ),
    pw.SizedBox(height: 24),
    _buildSectionHeader('SUMMARY', primaryColor),
    pw.Text(summary, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5), textAlign: pw.TextAlign.center),
    pw.SizedBox(height: 20),
    _buildSectionHeader('EXPERIENCE', primaryColor),
    ...experience.map((exp) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('${exp['company']} | ${exp['date']}', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          ...List<String>.from(exp['bullets'] ?? []).map((b) => pw.Text(b, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5))),
        ]
      ),
    )),
    pw.SizedBox(height: 10),
    _buildSectionHeader('EDUCATION', primaryColor),
    ...education.map((edu) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('${edu['school']} | ${edu['date']}', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
        ]
      ),
    )),
    pw.SizedBox(height: 10),
    _buildSectionHeader('SKILLS', primaryColor),
    pw.Center(child: pw.Column(children: skills.map((s) => pw.Text(s, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5), textAlign: pw.TextAlign.center)).toList())),
  ];
}

pw.Widget _buildSectionHeader(String title, PdfColor color) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Center(
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: color)),
          pw.SizedBox(height: 4),
          pw.Container(width: 30, height: 2, color: color),
        ]
      )
    )
  );
}
