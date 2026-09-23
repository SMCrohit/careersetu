import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate6Timeline({
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
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (profileImage != null)
          pw.Container(
            width: 80,
            height: 80,
            margin: const pw.EdgeInsets.only(right: 20),
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
            ),
          ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 5),
              pw.Text(goal.toUpperCase(), style: pw.TextStyle(fontSize: 14, color: primaryColor)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Text(email, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                  pw.SizedBox(width: 10),
                  pw.Text(phone, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                  pw.SizedBox(width: 10),
                  pw.Text(city, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
            ],
          )
        ),
      ]
    ),
    pw.SizedBox(height: 30),
    pw.Text('SUMMARY', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 10),
    pw.Text(summary, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
    pw.SizedBox(height: 30),
    pw.Text('EXPERIENCE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 15),
    ...experience.map((exp) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Timeline graphic
        pw.Container(
          width: 20,
          child: pw.Column(
            children: [
              pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: primaryColor, shape: pw.BoxShape.circle)),
              pw.Container(width: 2, height: 80, color: PdfColors.grey300), // Approximate height line
            ]
          )
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('${exp['company']}  •  ${exp['date']}', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                ...List<String>.from(exp['bullets'] ?? []).map((b) => pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.only(top: 4, right: 6), child: pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle))),
                    pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5))),
                  ]
                )),
              ]
            ),
          )
        )
      ]
    )),
    pw.SizedBox(height: 15),
    pw.Text('EDUCATION', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 15),
    ...education.map((edu) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 20,
          child: pw.Column(
            children: [
              pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: primaryColor, shape: pw.BoxShape.circle)),
              pw.Container(width: 2, height: 40, color: PdfColors.grey300),
            ]
          )
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('${edu['school']}  •  ${edu['date']}', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
              ]
            ),
          )
        )
      ]
    )),
    pw.SizedBox(height: 15),
    pw.Text('SKILLS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 10),
    pw.Text(skills.join('  |  '), style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
  ];
}
