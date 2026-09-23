import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

List<pw.Widget> buildTemplate2ModernSidebar({
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
        // Left Column (Sidebar)
        pw.Partition(
          flex: 3,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(20),
            color: primaryColor,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (profileImage != null)
                  pw.Container(
                    width: 120,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                      border: pw.Border.all(color: PdfColors.white, width: 3),
                    ),
                  )
                else
                  pw.Container(
                    width: 120,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '',
                        style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 30),
                // Contact Info
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('CONTACT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.5)),
                ),
                pw.SizedBox(height: 5),
                pw.Divider(color: PdfColors.white),
                pw.SizedBox(height: 10),
                _buildSidebarItem('Phone', phone),
                _buildSidebarItem('Email', email),
                _buildSidebarItem('Address', city),
                pw.SizedBox(height: 25),
                // Education
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('EDUCATION', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.5)),
                ),
                pw.SizedBox(height: 5),
                pw.Divider(color: PdfColors.white),
                pw.SizedBox(height: 10),
                ...education.map((edu) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.Text(edu['school'] ?? '', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
                      pw.Text(edu['date'] ?? '', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
                    ]
                  ),
                )),
                pw.SizedBox(height: 10),
                // Skills
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('SKILLS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.5)),
                ),
                pw.SizedBox(height: 5),
                pw.Divider(color: PdfColors.white),
                pw.SizedBox(height: 10),
                ...skills.map((s) => pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text('• $s', style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                  ),
                )),
              ],
            ),
          ),
        ),
        // Right Column (Main Content)
        pw.Partition(
          flex: 7,
          child: pw.Container(
            padding: const pw.EdgeInsets.only(left: 30, right: 30, top: 40, bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.Text(goal.toUpperCase(), style: pw.TextStyle(fontSize: 16, color: primaryColor, letterSpacing: 2)),
                pw.SizedBox(height: 30),
                
                // About Me
                _buildRightHeader('ABOUT ME', primaryColor),
                pw.SizedBox(height: 10),
                pw.Text(summary, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey800)),
                pw.SizedBox(height: 25),
                
                // Experience
                _buildRightHeader('EXPERIENCE', primaryColor),
                pw.SizedBox(height: 15),
                ...experience.map((exp) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.SizedBox(width: 5),
                          pw.Text('|', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey500)),
                          pw.SizedBox(width: 5),
                          pw.Text(exp['company'] ?? '', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                          pw.Spacer(),
                          pw.Text(exp['date'] ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ]
                      ),
                      pw.SizedBox(height: 8),
                      ...List<String>.from(exp['bullets'] ?? []).map((b) => pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 3, right: 6, left: 5),
                            child: pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle)),
                          ),
                          pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey800))),
                        ]
                      )),
                    ]
                  ),
                )),
                
                pw.SizedBox(height: 10),
                
                // Projects
                if (projects.isNotEmpty) ...[
                  _buildRightHeader('PROJECTS', primaryColor),
                  pw.SizedBox(height: 15),
                  ...projects.map((proj) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 15),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(proj['title'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 8),
                        ...List<String>.from(proj['bullets'] ?? []).map((b) => pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 3, right: 6, left: 5),
                              child: pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle)),
                            ),
                            pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey800))),
                          ]
                        )),
                      ]
                    ),
                  )),
                ]
              ],
            ),
          ),
        ),
      ],
    )
  ];
}

pw.Widget _buildSidebarItem(String title, String value) {
  return pw.Align(
    alignment: pw.Alignment.centerLeft,
    child: pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey200)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
        ]
      )
    )
  );
}

pw.Widget _buildRightHeader(String title, PdfColor color) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    decoration: pw.BoxDecoration(color: color),
    child: pw.Center(
      child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 2)),
    ),
  );
}
