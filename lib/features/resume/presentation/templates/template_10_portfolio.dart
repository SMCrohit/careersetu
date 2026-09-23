import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate10Portfolio({
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
        children: [
          pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          pw.SizedBox(height: 5),
          pw.Text(goal.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: 2)),
          pw.SizedBox(height: 15),
          pw.Text('$email | $phone | $city', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        ]
      )
    ),
    pw.SizedBox(height: 25),
    pw.Container(
      padding: const pw.EdgeInsets.all(15),
      color: PdfColor(primaryColor.red, primaryColor.green, primaryColor.blue, 0.1),
      child: pw.Text(summary, style: pw.TextStyle(fontSize: 11, lineSpacing: 1.5, fontStyle: pw.FontStyle.italic, color: PdfColors.black), textAlign: pw.TextAlign.center),
    ),
    pw.SizedBox(height: 30),
    
    // Emphasis on Projects
    pw.Text('FEATURED PROJECTS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.Divider(color: primaryColor, thickness: 2),
    pw.SizedBox(height: 15),
    ...projects.map((proj) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(proj['title'] ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          pw.SizedBox(height: 5),
          ...List<String>.from(proj['bullets'] ?? []).map((b) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(padding: const pw.EdgeInsets.only(top: 4, right: 6), child: pw.Container(width: 4, height: 4, decoration: pw.BoxDecoration(color: primaryColor))),
              pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5))),
            ]
          )),
        ]
      )
    )),
    
    pw.SizedBox(height: 15),
    pw.Text('PROFESSIONAL EXPERIENCE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.Divider(color: primaryColor, thickness: 2),
    pw.SizedBox(height: 15),
    ...experience.map((exp) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(exp['date'] ?? '', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            ]
          ),
          pw.Text(exp['company'] ?? '', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: primaryColor)),
          pw.SizedBox(height: 5),
          ...List<String>.from(exp['bullets'] ?? []).map((b) => pw.Text('• $b', style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5))),
        ]
      )
    )),
    
    pw.SizedBox(height: 15),
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('EDUCATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              pw.Divider(color: primaryColor, thickness: 2),
              pw.SizedBox(height: 10),
              ...education.map((edu) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(edu['school'] ?? '', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(edu['date'] ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ]
                )
              )),
            ]
          )
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CORE SKILLS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              pw.Divider(color: primaryColor, thickness: 2),
              pw.SizedBox(height: 10),
              ...skills.map((s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  children: [
                    pw.Container(width: 6, height: 6, color: primaryColor),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: pw.Text(s, style: const pw.TextStyle(fontSize: 11))),
                  ]
                )
              )),
            ]
          )
        ),
      ]
    )
  ];
}
