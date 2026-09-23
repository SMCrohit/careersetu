import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate1Professional({
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
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                pw.SizedBox(height: 5),
                pw.Text(goal.toUpperCase(), style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Text('$email  •  $phone  •  $city', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
              ],
            )
          ),
          if (profileImage != null)
            pw.Container(
              width: 80,
              height: 80,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
              ),
            )
        ]
      )
    ),
    pw.SizedBox(height: 20),
    pw.Text('SUMMARY', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 5),
    pw.Text(summary, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
    pw.SizedBox(height: 20),
    pw.Text('EXPERIENCE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 10),
    ...experience.map((exp) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(exp['date'] ?? '', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            ]
          ),
          pw.Text(exp['company'] ?? '', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 5),
          ...List<String>.from(exp['bullets'] ?? []).map((b) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(padding: const pw.EdgeInsets.only(top: 4, right: 6), child: pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle))),
              pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5))),
            ]
          )),
        ]
      ),
    )),
    pw.SizedBox(height: 10),
    pw.Text('EDUCATION', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 10),
    ...education.map((edu) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(edu['school'] ?? '', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
            ]
          ),
          pw.Text(edu['date'] ?? '', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        ]
      ),
    )),
    pw.SizedBox(height: 10),
    pw.Text('SKILLS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 5),
    pw.Text(skills.join(', '), style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
  ];
}
