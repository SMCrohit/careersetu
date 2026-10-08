import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Flex ratio of the dark left column to the light right column.
const _leftFlex = 4;
const _rightFlex = 6;

/// Paints the dark left column behind every page, so it continues when the resume spans pages.
pw.Widget buildTemplate3Background(pw.Context context) {
  return pw.FullPage(
    ignoreMargins: true,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(flex: _leftFlex, child: pw.Container(color: PdfColors.black)),
        pw.Expanded(flex: _rightFlex, child: pw.SizedBox()),
      ],
    ),
  );
}

/// Space kept at the top of continuation pages (the first page starts with full-bleed headers).
pw.Widget buildTemplate3Header(pw.Context context) {
  return pw.SizedBox(height: context.pageNumber > 1 ? 30 : 0);
}

// Each column is a flat list of small widgets so the PDF can break between them across pages.
// Wrapping a whole column in one Container/Padding makes it unsplittable (TooManyPagesException).
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
  pw.Widget left(pw.Widget child) => pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 20), child: child);
  pw.Widget right(pw.Widget child) => pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 30), child: child);
  pw.Widget leftTitle(String text) => left(pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ));

  final leftColumn = <pw.Widget>[
    // Graphical Top Left (Grey circle in the sample)
    pw.Container(
      height: 200,
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.only(bottomRight: pw.Radius.circular(100)),
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
                decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.white),
                child: pw.Center(
                  child: pw.Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '',
                      style: pw.TextStyle(fontSize: 60, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ),
              ),
      ),
    ),
    pw.SizedBox(height: 30),
    left(pw.Text('CONTACT DETAILS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
    pw.SizedBox(height: 15),
    left(_buildContactRow('Phone', phone)),
    left(_buildContactRow('Location', city)),
    left(_buildContactRow('Email', email)),
    if (summary.isNotEmpty) ...[
      pw.SizedBox(height: 30),
      _buildSectionDivider(primaryColor),
      pw.SizedBox(height: 15),
      leftTitle('OBJECTIVE'),
      pw.SizedBox(height: 15),
      left(pw.Text(summary, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400, lineSpacing: 1.5), textAlign: pw.TextAlign.justify)),
    ],
    if (skills.isNotEmpty) ...[
      pw.SizedBox(height: 30),
      _buildSectionDivider(primaryColor),
      pw.SizedBox(height: 15),
      leftTitle('SKILLS'),
      pw.SizedBox(height: 15),
      ...skills.map((s) => left(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(s, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey300))),
                pw.Container(
                  width: 60,
                  height: 6,
                  decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(3)),
                ),
              ],
            ),
          ))),
    ],
    if (projects.isNotEmpty) ...[
      pw.SizedBox(height: 30),
      _buildSectionDivider(primaryColor),
      pw.SizedBox(height: 15),
      leftTitle('PROJECTS'),
      pw.SizedBox(height: 15),
      ...projects.map((p) => left(pw.Text(p['title'] ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey300, lineSpacing: 1.5)))),
    ],
    pw.SizedBox(height: 20),
  ];

  final rightColumn = <pw.Widget>[
    // Top Right Header (Primary background)
    pw.Container(
      height: 120,
      padding: const pw.EdgeInsets.only(left: 30, right: 20, top: 40),
      color: primaryColor,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(name, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          pw.Text(goal, style: const pw.TextStyle(fontSize: 16, color: PdfColors.black)),
        ],
      ),
    ),
    pw.SizedBox(height: 30),
    if (education.isNotEmpty) ...[
      right(_buildRightHeaderBox('EDUCATION', primaryColor)),
      pw.SizedBox(height: 15),
      ...education.map((edu) => right(pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(edu['degree'] ?? '', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                pw.Text([edu['school'], edu['date']].where((x) => (x ?? '').toString().isNotEmpty).join(' | '),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              ],
            ),
          ))),
      pw.SizedBox(height: 25),
    ],
    if (experience.isNotEmpty) ...[
      right(_buildRightHeaderBox('WORK EXPERIENCE', primaryColor)),
      pw.SizedBox(height: 15),
      for (final exp in experience) ...[
        right(pw.Text(exp['title'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
        right(pw.Text([exp['company'], exp['date']].where((x) => (x ?? '').toString().isNotEmpty).join(' | '),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800))),
        pw.SizedBox(height: 6),
        ...List<String>.from(exp['bullets'] ?? []).map((b) => right(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3.5, right: 6),
                    child: pw.Container(width: 3, height: 3, decoration: const pw.BoxDecoration(color: PdfColors.grey700, shape: pw.BoxShape.circle)),
                  ),
                  pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.5, color: PdfColors.grey700))),
                ],
              ),
            ))),
        pw.SizedBox(height: 14),
      ],
    ],
  ];

  return [
    pw.Partitions(
      children: [
        pw.Partition(
          flex: _leftFlex,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: leftColumn),
        ),
        pw.Partition(
          flex: _rightFlex,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: rightColumn),
        ),
      ],
    ),
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
