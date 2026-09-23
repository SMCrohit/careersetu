import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate9Grid({
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
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          if (profileImage != null)
            pw.Container(
              width: 70,
              height: 70,
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
                pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                pw.Text(goal.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Text('$email  •  $phone  •  $city', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
              ]
            )
          )
        ]
      )
    ),
    pw.SizedBox(height: 20),
    pw.Text('SUMMARY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    pw.SizedBox(height: 5),
    pw.Text(summary, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
    pw.SizedBox(height: 20),
    
    // Grid Layout using Partitions
    pw.Partitions(
      children: [
        // Left Column: Education & Skills
        pw.Partition(
          flex: 4,
          child: pw.Container(
            padding: const pw.EdgeInsets.only(right: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EDUCATION', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                pw.SizedBox(height: 10),
                ...education.map((edu) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(edu['school'] ?? '', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)),
                      pw.Text(edu['date'] ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ]
                  ),
                )),
                pw.SizedBox(height: 20),
                pw.Text('SKILLS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                pw.SizedBox(height: 10),
                ...skills.map((s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(s, style: const pw.TextStyle(fontSize: 10)),
                )),
              ],
            )
          )
        ),
        
        // Right Column: Experience
        pw.Partition(
          flex: 6,
          child: pw.Container(
            padding: const pw.EdgeInsets.only(left: 20),
            decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.grey300))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EXPERIENCE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                pw.SizedBox(height: 10),
                ...experience.map((exp) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(exp['date'] ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ]
                      ),
                      pw.Text(exp['company'] ?? '', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)),
                      pw.SizedBox(height: 5),
                      ...List<String>.from(exp['bullets'] ?? []).map((b) => pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.only(top: 3, right: 5), child: pw.Text('•', style: pw.TextStyle(fontSize: 10, color: primaryColor))),
                          pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5))),
                        ]
                      )),
                    ]
                  ),
                )),
                
                if (projects.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('PROJECTS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 10),
                  ...projects.map((proj) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(proj['title'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        ...List<String>.from(proj['bullets'] ?? []).map((b) => pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.only(top: 3, right: 5), child: pw.Text('•', style: pw.TextStyle(fontSize: 10, color: primaryColor))),
                            pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5))),
                          ]
                        )),
                      ]
                    )
                  )),
                ]
              ]
            )
          )
        )
      ]
    )
  ];
}
