import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate8Accent({
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
    pw.Container(
      height: 10,
      width: double.infinity,
      color: primaryColor,
    ),
    pw.SizedBox(height: 30),
    pw.Center(
      child: pw.Column(
        children: [
          if (profileImage != null)
            pw.Container(
              width: 90,
              height: 90,
              margin: const pw.EdgeInsets.only(bottom: 15),
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
              ),
            ),
          pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text(goal.toUpperCase(), style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        ]
      )
    ),
    pw.SizedBox(height: 20),
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300), bottom: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Text(email, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(phone, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(city, style: const pw.TextStyle(fontSize: 11)),
        ]
      )
    ),
    pw.SizedBox(height: 30),
    _buildSectionHeader('SUMMARY', primaryColor),
    pw.SizedBox(height: 10),
    pw.Text(summary, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
    pw.SizedBox(height: 25),
    _buildSectionHeader('EXPERIENCE', primaryColor),
    pw.SizedBox(height: 15),
    ...experience.map((exp) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.only(left: 15),
      decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: primaryColor, width: 3))),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(exp['date'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            ]
          ),
          pw.Text(exp['company'] ?? '', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          ...List<String>.from(exp['bullets'] ?? []).map((b) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(padding: const pw.EdgeInsets.only(top: 4, right: 6), child: pw.Text('•', style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold))),
              pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5))),
            ]
          )),
        ]
      ),
    )),
    pw.SizedBox(height: 10),
    _buildSectionHeader('EDUCATION', primaryColor),
    pw.SizedBox(height: 15),
    ...education.map((edu) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.only(left: 15),
      decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: primaryColor, width: 3))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(edu['school'] ?? '', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
            ]
          ),
          pw.Text(edu['date'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
        ]
      ),
    )),
    pw.SizedBox(height: 10),
    _buildSectionHeader('SKILLS', primaryColor),
    pw.SizedBox(height: 10),
    pw.Text(skills.join(', '), style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
  ];
}

pw.Widget _buildSectionHeader(String title, PdfColor color) {
  return pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color, letterSpacing: 1.5));
}
