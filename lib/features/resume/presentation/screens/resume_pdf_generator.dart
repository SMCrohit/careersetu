import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../auth/domain/user_model.dart';
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

  static Future<Uint8List> generateResume(User user, int templateIndex) async {
    await _fetchProfileImage(user.profileImageUrl);

    final pdf = pw.Document();

    final name = user.fullName;
    final email = user.email;
    final phone = user.mobileNumber;
    final city = user.city;
    final goal = user.goal;

    final summary = user.resumeData?['summary'] ?? '';
    
    final experience = List<Map<String, dynamic>>.from(user.resumeData?['experience'] ?? []);

    final education = List<Map<String, dynamic>>.from(user.resumeData?['education'] ?? []);

    final skillsText = user.resumeData?['skills'] ?? '';
    final skills = skillsText.isEmpty ? <String>[] : skillsText.split('\n');

    final projects = List<Map<String, dynamic>>.from(user.resumeData?['projects'] ?? []);

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
        pageFormat: PdfPageFormat.a4,
        margin: margin,
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
