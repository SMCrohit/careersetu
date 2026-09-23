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
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200) {
        _cachedProfileImage = pw.MemoryImage(Uint8List.fromList(response.data));
        _cachedImageUrl = url;
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

    final summary = user.resumeData?['summary'] ?? 
        'Dedicated and results-driven professional seeking opportunities as a $goal. Proven track record of delivering high-quality solutions, adapting quickly to new environments, and collaborating effectively in cross-functional teams to exceed organizational objectives.';
    
    final experience = List<Map<String, dynamic>>.from(user.resumeData?['experience'] ?? [
      {
        'title': goal,
        'company': 'Tech Solutions Corp',
        'date': '2021 - Present',
        'bullets': [
          'Spearheaded the development of a flagship mobile application, resulting in a 40% increase in user retention.',
          'Optimized database queries and backend architecture, reducing API latency by over 30%.',
          'Mentored junior team members and established best practices for code reviews.',
        ]
      },
      {
        'title': 'Junior $goal',
        'company': 'StartUp Innovate Inc',
        'date': '2019 - 2021',
        'bullets': [
          'Assisted in the migration of legacy monolithic systems to a microservices architecture.',
          'Collaborated with the QA team to increase test coverage from 45% to 85%.',
          'Resolved critical production bugs, achieving a 99.9% uptime SLA.',
        ]
      }
    ]);

    final education = List<Map<String, dynamic>>.from(user.resumeData?['education'] ?? [
      {
        'degree': 'B.Tech in Computer Science',
        'date': '2015 - 2019',
        'school': 'National Institute of Technology'
      }
    ]);

    final skillsText = user.resumeData?['skills'] ?? 
        'Technical: Flutter, Dart, React, Node.js, Python, Firebase, PostgreSQL, Docker, AWS\nSoft Skills: Leadership, Agile Methodologies, Problem Solving, Public Speaking';
    final skills = skillsText.split('\n').cast<String>();

    final projects = List<Map<String, dynamic>>.from(user.resumeData?['projects'] ?? [
      {
        'title': 'CareerSetu Platform',
        'bullets': [
          'Built a scalable career preparation application from scratch.',
          'Implemented complex state management and responsive UI components.'
        ]
      }
    ]);

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
