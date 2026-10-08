/// The resume being built. Same shape as the backend draft (`backend/resume_builder.py`).
/// Fields are mutable so the editor can work on a [copy] directly.
class ResumeDraft {
  String fullName;
  String email;
  String phone;
  String city;
  String headline;
  String summary;
  List<ExperienceEntry> experience;
  List<EducationEntry> education;
  List<String> skills;
  List<ProjectEntry> projects;
  List<CertificationEntry> certifications;
  List<String> languages;
  ResumeLinks links;

  ResumeDraft({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.headline = '',
    this.summary = '',
    List<ExperienceEntry>? experience,
    List<EducationEntry>? education,
    List<String>? skills,
    List<ProjectEntry>? projects,
    List<CertificationEntry>? certifications,
    List<String>? languages,
    ResumeLinks? links,
  })  : experience = experience ?? [],
        education = education ?? [],
        skills = skills ?? [],
        projects = projects ?? [],
        certifications = certifications ?? [],
        languages = languages ?? [],
        links = links ?? ResumeLinks();

  bool get hasContent =>
      summary.isNotEmpty || experience.isNotEmpty || education.isNotEmpty || skills.isNotEmpty || projects.isNotEmpty;

  factory ResumeDraft.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return ResumeDraft(
      fullName: _str(json['full_name']),
      email: _str(json['email']),
      phone: _str(json['phone']),
      city: _str(json['city']),
      headline: _str(json['headline']),
      summary: _str(json['summary']),
      experience: _list(json['experience']).map(ExperienceEntry.fromJson).toList(),
      education: _list(json['education']).map(EducationEntry.fromJson).toList(),
      skills: _strings(json['skills']),
      projects: _list(json['projects']).map(ProjectEntry.fromJson).toList(),
      certifications: _list(json['certifications']).map(CertificationEntry.fromJson).toList(),
      languages: _strings(json['languages']),
      links: ResumeLinks.fromJson(json['links'] is Map ? Map<String, dynamic>.from(json['links']) : {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'city': city,
        'headline': headline,
        'summary': summary,
        'experience': experience.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'skills': skills,
        'projects': projects.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'languages': languages,
        'links': links.toJson(),
      };

  ResumeDraft copy() => ResumeDraft.fromJson(toJson());
}

class ExperienceEntry {
  String title;
  String company;
  String location;
  String start;
  String end;
  List<String> bullets;

  ExperienceEntry({this.title = '', this.company = '', this.location = '', this.start = '', this.end = '', List<String>? bullets})
      : bullets = bullets ?? [];

  factory ExperienceEntry.fromJson(Map<String, dynamic> j) => ExperienceEntry(
        title: _str(j['title']),
        company: _str(j['company']),
        location: _str(j['location']),
        start: _str(j['start']),
        end: _str(j['end']),
        bullets: _strings(j['bullets']),
      );

  Map<String, dynamic> toJson() =>
      {'title': title, 'company': company, 'location': location, 'start': start, 'end': end, 'bullets': bullets};
}

class EducationEntry {
  String degree;
  String school;
  String start;
  String end;
  String score;

  EducationEntry({this.degree = '', this.school = '', this.start = '', this.end = '', this.score = ''});

  factory EducationEntry.fromJson(Map<String, dynamic> j) => EducationEntry(
        degree: _str(j['degree']),
        school: _str(j['school']),
        start: _str(j['start']),
        end: _str(j['end']),
        score: _str(j['score']),
      );

  Map<String, dynamic> toJson() => {'degree': degree, 'school': school, 'start': start, 'end': end, 'score': score};
}

class ProjectEntry {
  String title;
  String description;
  List<String> bullets;

  ProjectEntry({this.title = '', this.description = '', List<String>? bullets}) : bullets = bullets ?? [];

  factory ProjectEntry.fromJson(Map<String, dynamic> j) =>
      ProjectEntry(title: _str(j['title']), description: _str(j['description']), bullets: _strings(j['bullets']));

  Map<String, dynamic> toJson() => {'title': title, 'description': description, 'bullets': bullets};
}

class CertificationEntry {
  String title;
  String organization;
  String year;

  CertificationEntry({this.title = '', this.organization = '', this.year = ''});

  factory CertificationEntry.fromJson(Map<String, dynamic> j) =>
      CertificationEntry(title: _str(j['title']), organization: _str(j['organization']), year: _str(j['year']));

  Map<String, dynamic> toJson() => {'title': title, 'organization': organization, 'year': year};
}

class ResumeLinks {
  String linkedin;
  String github;
  String portfolio;

  ResumeLinks({this.linkedin = '', this.github = '', this.portfolio = ''});

  factory ResumeLinks.fromJson(Map<String, dynamic> j) =>
      ResumeLinks(linkedin: _str(j['linkedin']), github: _str(j['github']), portfolio: _str(j['portfolio']));

  Map<String, dynamic> toJson() => {'linkedin': linkedin, 'github': github, 'portfolio': portfolio};
}

String _str(dynamic v) => v == null ? '' : v.toString().trim();

List<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList() : [];
