import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate7Bold({
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
    pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: -1)),
    pw.SizedBox(height: 5),
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: primaryColor,
      child: pw.Text(goal.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    ),
    pw.SizedBox(height: 15),
    pw.Row(
      children: [
        pw.Text(email, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.Text('   /   ', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey400)),
        pw.Text(phone, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.Text('   /   ', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey400)),
        pw.Text(city, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
      ],
    ),
    pw.SizedBox(height: 40),
    _buildSectionHeader('SUMMARY', primaryColor),
    pw.SizedBox(height: 10),
    pw.Text(summary, style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
    pw.SizedBox(height: 30),
    
    _buildSectionHeader('EXPERIENCE', primaryColor),
    pw.SizedBox(height: 15),
    ...experience.map((exp) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('${exp['company']} | ${exp['date']}', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: primaryColor)),
          pw.SizedBox(height: 8),
          ...List<String>.from(exp['bullets'] ?? []).map((b) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(padding: const pw.EdgeInsets.only(top: 5, right: 8), child: pw.Container(width: 4, height: 4, decoration: pw.BoxDecoration(color: primaryColor))),
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
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(edu['school'] ?? '', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
            ]
          ),
          pw.Text(edu['date'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
        ]
      ),
    )),
    
    pw.SizedBox(height: 20),
    _buildSectionHeader('SKILLS', primaryColor),
    pw.SizedBox(height: 10),
    pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((s) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: primaryColor), borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Text(s, style: pw.TextStyle(fontSize: 10, color: primaryColor, fontWeight: pw.FontWeight.bold)),
      )).toList(),
    ),
  ];
}

pw.Widget _buildSectionHeader(String title, PdfColor color) {
  return pw.Row(
    children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: 1)),
      pw.SizedBox(width: 15),
      pw.Expanded(child: pw.Divider(color: color, thickness: 2)),
    ]
  );
}
