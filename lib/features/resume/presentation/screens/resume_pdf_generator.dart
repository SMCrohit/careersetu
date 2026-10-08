import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/resume_draft.dart';
import '../templates/template_1_professional.dart';
import '../templates/template_2_modern_sidebar.dart';
import '../templates/template_3_graphic_split.dart';
import '../templates/template_4_minimalist.dart';
import '../templates/template_5_executive.dart';
import '../templates/template_6_timeline.dart';
import '../templates/template_7_bold.dart';
import '../templates/template_8_accent.dart';
import '../templates/template_9_grid.dart';
import '../templates/template_10_portfolio.dart';

class ResumePdfGenerator {
  static pw.MemoryImage? _cachedProfileImage;
  static String? _cachedImageUrl;

  static Future<void> _fetchProfileImage(String? url) async {
    if (url == null || url.isEmpty) return;
    if (_cachedProfileImage != null && _cachedImageUrl == url) return;

    try {
      if (url.startsWith('data:image')) {
        final base64String = url.split(',').last.replaceAll(RegExp(r'\s+'), '');
        String padded = base64String;
        int padding = padded.length % 4;
        if (padding != 0) padded += '=' * (4 - padding);
        
        final bytes = Uri.parse('data:image/jpeg;base64,$padded').data!.contentAsBytes();
        _cachedProfileImage = pw.MemoryImage(bytes);
        _cachedImageUrl = url;
      } else {
        final dio = Dio();
        final response = await dio.get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.statusCode == 200) {
          _cachedProfileImage = pw.MemoryImage(Uint8List.fromList(response.data));
          _cachedImageUrl = url;
        }
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  static String _range(String start, String end) => [start, end].where((e) => e.isNotEmpty).join(' - ');

  /// Builds the PDF for [draft] using one of the 10 templates.
  static Future<Uint8List> generateResume(ResumeDraft draft, String? profileImageUrl, int templateIndex) async {
    await _fetchProfileImage(profileImageUrl);

    final pdf = pw.Document();

    final name = draft.fullName;
    final email = draft.email;
    final phone = draft.phone;
    final city = draft.city;
    final goal = draft.headline;
    final summary = draft.summary;

    // Map the draft into the shapes the templates read.
    final experience = draft.experience
        .map((e) => <String, dynamic>{
              'title': e.title,
              'company': [e.company, e.location].where((x) => x.isNotEmpty).join(', '),
              'date': _range(e.start, e.end),
              'bullets': e.bullets,
            })
        .toList();
    final education = draft.education
        .map((e) => <String, dynamic>{
              'degree': e.score.isNotEmpty ? '${e.degree} (${e.score})' : e.degree,
              'school': e.school,
              'date': _range(e.start, e.end),
            })
        .toList();
    final skills = draft.skills;
    final projects = draft.projects
        .map((p) => <String, dynamic>{
              'title': p.title,
              'bullets': [if (p.description.isNotEmpty) p.description, ...p.bullets],
            })
        .toList();

    final colors = [
      PdfColors.blue900,
      PdfColors.black,
      PdfColors.teal700,
      PdfColors.red900,
      PdfColors.blueGrey800,
      PdfColors.grey800,
      PdfColors.deepOrange700,
      PdfColors.green800,
      PdfColors.deepPurple700,
      PdfColor.fromHex('#B8860B') // Gold
    ];
    final primaryColor = colors[templateIndex % colors.length];
    
    // Assign specific margins based on template
    pw.EdgeInsets margin = const pw.EdgeInsets.all(32);
    if (templateIndex == 1 || templateIndex == 2 || templateIndex == 4) {
      margin = const pw.EdgeInsets.all(0); // Full bleed for sidebar/graphic/executive
    } else if (templateIndex == 7) {
      margin = const pw.EdgeInsets.only(top: 0, left: 32, right: 32, bottom: 32); // Accent top
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: margin,
          buildBackground: templateIndex == 2 ? buildTemplate3Background : null,
        ),
        header: templateIndex == 2 ? buildTemplate3Header : null,
        build: (context) {
          switch (templateIndex) {
            case 0:
              return buildTemplate1Professional(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 1:
              return buildTemplate2ModernSidebar(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 2:
              return buildTemplate3GraphicSplit(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 3:
              return buildTemplate4Minimalist(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 4:
              return buildTemplate5Executive(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 5:
              return buildTemplate6Timeline(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 6:
              return buildTemplate7Bold(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 7:
              return buildTemplate8Accent(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 8:
              return buildTemplate9Grid(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            case 9:
              return buildTemplate10Portfolio(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
            default:
              return buildTemplate1Professional(name: name, email: email, phone: phone, city: city, goal: goal, summary: summary, experience: experience, education: education, skills: skills, projects: projects, primaryColor: primaryColor, profileImage: _cachedProfileImage);
          }
        },
      )
    );

    return pdf.save();
  }
}
