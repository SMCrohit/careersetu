/// Where a job is based. The backend stores `{area, city, state, pincode}`; older rows may be a plain string.
class JobLocation {
  final String area;
  final String city;
  final String state;
  final String pincode;

  const JobLocation({this.area = '', this.city = '', this.state = '', this.pincode = ''});

  factory JobLocation.fromJson(dynamic json) {
    if (json is Map) {
      return JobLocation(
        area: _str(json['area']),
        city: _str(json['city']),
        state: _str(json['state']),
        pincode: _str(json['pincode']),
      );
    }
    return JobLocation(city: _str(json));
  }

  /// "Area, City" for cards.
  String get short => [area, city].where((e) => e.isNotEmpty).join(', ');

  /// "Area, City, State - Pincode" for the details page.
  String get full {
    final place = [area, city, state].where((e) => e.isNotEmpty).join(', ');
    return pincode.isNotEmpty ? '$place - $pincode' : place;
  }
}

class JobModel {
  final String id;
  final String title;
  final String companyName;
  final String jobType;
  final String workModel;
  final JobLocation location;
  final String description;
  final bool isFeatured;

  /// 'manual_review', 'direct_email' or 'external_link'.
  final String routingMode;
  final String externalApplyUrl;
  final String companyWebsite;
  final int vacancies;
  final String shiftTiming;
  final bool isCoverLetterRequired;
  final List<String> screeningQuestions;
  final int? salaryMin;
  final int? salaryMax;
  final String salaryType;
  final String currency;
  final double experienceYears;
  final String educationRequired;
  final List<String> skills;
  final List<String> languages;
  final DateTime? createdDatetime;
  final int applicantsCount;
  final bool hasApplied;

  const JobModel({
    required this.id,
    required this.title,
    this.companyName = '',
    this.jobType = '',
    this.workModel = '',
    this.location = const JobLocation(),
    this.description = '',
    this.isFeatured = false,
    this.routingMode = 'manual_review',
    this.externalApplyUrl = '',
    this.companyWebsite = '',
    this.vacancies = 1,
    this.shiftTiming = '',
    this.isCoverLetterRequired = false,
    this.screeningQuestions = const [],
    this.salaryMin,
    this.salaryMax,
    this.salaryType = 'Per Year',
    this.currency = 'INR',
    this.experienceYears = 0,
    this.educationRequired = '',
    this.skills = const [],
    this.languages = const [],
    this.createdDatetime,
    this.applicantsCount = 0,
    this.hasApplied = false,
  });

  bool get isExternal => routingMode == 'external_link' && externalApplyUrl.isNotEmpty;

  bool get isNew => createdDatetime != null && DateTime.now().difference(createdDatetime!).inDays <= 7;

  /// First letter of the company for the avatar.
  String get initial {
    final name = (companyName.isNotEmpty ? companyName : title).trim();
    return name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();
  }

  String get experienceLabel {
    if (experienceYears <= 0) return 'Fresher';
    final years = experienceYears == experienceYears.roundToDouble() ? experienceYears.toInt().toString() : experienceYears.toString();
    return '$years+ yrs';
  }

  String get salaryLabel {
    if ((salaryMin ?? 0) <= 0 && (salaryMax ?? 0) <= 0) return 'Not disclosed';
    final symbol = currency == 'INR' ? '₹' : '$currency ';
    final per = switch (salaryType) {
      'Per Month' => ' / month',
      'Per Hour' => ' / hour',
      'Per Year' => ' / year',
      _ => salaryType.isNotEmpty ? ' / ${salaryType.toLowerCase().replaceFirst('per ', '')}' : '',
    };
    final min = salaryMin ?? 0;
    final max = salaryMax ?? 0;
    if (min > 0 && max > 0 && min != max) return '$symbol${_money(min)} – $symbol${_money(max)}$per';
    return '$symbol${_money(max > 0 ? max : min)}$per';
  }

  String get postedAgo {
    if (createdDatetime == null) return '';
    final days = DateTime.now().difference(createdDatetime!).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '${days}d ago';
    if (days < 30) return '${days ~/ 7}w ago';
    if (days < 365) return '${days ~/ 30}mo ago';
    return '${days ~/ 365}y ago';
  }

  JobModel copyWith({bool? hasApplied, int? applicantsCount}) => JobModel(
        id: id,
        title: title,
        companyName: companyName,
        jobType: jobType,
        workModel: workModel,
        location: location,
        description: description,
        isFeatured: isFeatured,
        routingMode: routingMode,
        externalApplyUrl: externalApplyUrl,
        companyWebsite: companyWebsite,
        vacancies: vacancies,
        shiftTiming: shiftTiming,
        isCoverLetterRequired: isCoverLetterRequired,
        screeningQuestions: screeningQuestions,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        salaryType: salaryType,
        currency: currency,
        experienceYears: experienceYears,
        educationRequired: educationRequired,
        skills: skills,
        languages: languages,
        createdDatetime: createdDatetime,
        applicantsCount: applicantsCount ?? this.applicantsCount,
        hasApplied: hasApplied ?? this.hasApplied,
      );

  /// Null-safe so one odd field never breaks the whole list.
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: _str(json['id']),
      title: _str(json['title']).isNotEmpty ? _str(json['title']) : 'Untitled job',
      companyName: _str(json['company_name'] ?? json['company']),
      jobType: _str(json['job_type'] ?? json['type']),
      workModel: _str(json['work_model']),
      location: JobLocation.fromJson(json['location']),
      description: _str(json['description']),
      isFeatured: json['is_featured'] == true,
      routingMode: _str(json['application_routing_mode']).isNotEmpty ? _str(json['application_routing_mode']) : 'manual_review',
      externalApplyUrl: _str(json['external_apply_url']),
      companyWebsite: _str(json['company_website']),
      vacancies: _int(json['vacancies_count']) ?? 1,
      shiftTiming: _str(json['shift_timing']),
      isCoverLetterRequired: json['is_cover_letter_required'] == true,
      screeningQuestions: _strings(json['screening_questions']),
      salaryMin: _int(json['salary_min']),
      salaryMax: _int(json['salary_max']),
      salaryType: _str(json['salary_type']).isNotEmpty ? _str(json['salary_type']) : 'Per Year',
      currency: _str(json['currency']).isNotEmpty ? _str(json['currency']) : 'INR',
      experienceYears: (json['experience_required_years'] as num?)?.toDouble() ?? 0,
      educationRequired: _str(json['education_required']),
      skills: _strings(json['skills_required']),
      languages: _strings(json['languages_required']),
      createdDatetime: DateTime.tryParse(_str(json['created_datetime'])),
      applicantsCount: _int(json['applicants_count']) ?? 0,
      hasApplied: json['has_applied'] == true,
    );
  }
}

/// Formats rupees as "45K", "3.5L" or "1.2Cr".
String _money(int value) {
  String trim(double v) => v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll(RegExp(r'\.0$'), '');
  if (value >= 10000000) return '${trim(value / 10000000)}Cr';
  if (value >= 100000) return '${trim(value / 100000)}L';
  if (value >= 1000) return '${trim(value / 1000)}K';
  return value.toString();
}

String _str(dynamic v) => v == null ? '' : v.toString().trim();

int? _int(dynamic v) => v is num ? v.toInt() : int.tryParse(_str(v));

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList() : const [];
