import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate3GraphicSplit({
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
    pw.Partitions(
      children: [
        // Left Column (Dark Theme)
        pw.Partition(
          flex: 4,
          child: pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.only(top: 0, bottom: 20),
            child: pw.Column(
              children: [
                // Graphical Top Left (Grey circle in the sample)
                pw.Container(
                  width: double.infinity,
                  height: 200,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    borderRadius: const pw.BorderRadius.only(bottomRight: pw.Radius.circular(100)),
                  ),
                  child: pw.Center(
                    child: profileImage != null
                        ? pw.Container(
                            width: 140,
                            height: 140,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                              border: pw.Border.all(color: PdfColors.black, width: 4),
                            ),
                          )
                        : pw.Container(
                            width: 140,
                            height: 140,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColors.white,
                            ),
                            child: pw.Center(
                              child: pw.Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '', style: pw.TextStyle(fontSize: 60, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            )
                          ),
                  ),
                ),
                pw.SizedBox(height: 30),
                
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CONTACT DETAILS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.SizedBox(height: 15),
                      _buildContactRow('Phone', phone),
                      _buildContactRow('Location', city),
                      _buildContactRow('Email', email),
                      
                      pw.SizedBox(height: 30),
                      _buildSectionDivider(primaryColor),
                      pw.SizedBox(height: 15),
                      pw.Center(child: pw.Text('OBJECTIVE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                      pw.SizedBox(height: 15),
                      pw.Text(summary, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400, lineSpacing: 1.5), textAlign: pw.TextAlign.justify),
                      
                      pw.SizedBox(height: 30),
                      _buildSectionDivider(primaryColor),
                      pw.SizedBox(height: 15),
                      pw.Center(child: pw.Text('SKILLS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                      pw.SizedBox(height: 15),
                      ...skills.map((s) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(child: pw.Text(s, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey300))),
                            pw.Container(
                              width: 60,
                              height: 6,
                              decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(3)),
                            )
                          ]
                        ),
                      )),
                      
                      pw.SizedBox(height: 30),
                      _buildSectionDivider(primaryColor),
                      pw.SizedBox(height: 15),
                      pw.Center(child: pw.Text('PROJECTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                      pw.SizedBox(height: 15),
                      ...projects.map((p) => pw.Text(p['title'] ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey300, lineSpacing: 1.5))),
                    ],
                  ),
                ),
              ],
            ),
          )
        ),
        
        // Right Column (White/Light Theme)
        pw.Partition(
          flex: 6,
          child: pw.Container(
            padding: const pw.EdgeInsets.only(top: 0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Right Header (Yellow/Primary background)
                pw.Container(
                  width: double.infinity,
                  height: 120,
                  padding: const pw.EdgeInsets.only(left: 30, right: 20, top: 40),
                  color: primaryColor,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(name, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.Text(goal, style: const pw.TextStyle(fontSize: 16, color: PdfColors.black)),
                    ]
                  ),
                ),
                
                pw.Padding(
                  padding: const pw.EdgeInsets.all(30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildRightHeaderBox('EDUCATION', primaryColor),
                      pw.SizedBox(height: 15),
                      ...education.map((edu) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(edu['degree'] ?? '', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                            pw.Text('${edu['school']} | ${edu['date']}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          ]
                        ),
                      )),
                      
                      pw.SizedBox(height: 25),
                      _buildRightHeaderBox('WORK EXPERIENCE', primaryColor),
                      pw.SizedBox(height: 15),
                      ...experience.map((exp) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 20),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            pw.Text('${exp['company']} | ${exp['date']}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              (exp['bullets'] as List<dynamic>?)?.join(' ') ?? '', 
                              style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.5, color: PdfColors.grey700)
                            ),
                          ]
                        ),
                      )),
                    ]
                  ),
                ),
              ],
            ),
          )
        ),
      ]
    )
  ];
}

pw.Widget _buildContactRow(String iconPlaceholder, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(
      children: [
        pw.Container(width: 14, height: 14, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.white))),
        pw.SizedBox(width: 10),
        pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10, color: PdfColors.white))),
      ]
    )
  );
}

pw.Widget _buildSectionDivider(PdfColor color) {
  return pw.Center(
    child: pw.Container(width: 40, height: 4, decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(2))),
  );
}

pw.Widget _buildRightHeaderBox(String title, PdfColor color) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: pw.BoxDecoration(color: color),
    child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
  );
}
