class User {
  final String? id;
  final String mobileNumber;
  final String whatsappNumber;
  final String fullName;
  final String email;
  final String city;
  final String goal;
  final String? profileImageUrl;
  final Map<String, dynamic>? resumeData;
  final int profileCompletionScore;
  
  // Location & Personal
  final String state;
  final String pincode;
  final String country;
  final String address;
  final String? dob;
  final String gender;
  final String maritalStatus;
  
  // Overview & Logistics
  final String summary;
  final double yearsOfExperience;
  final int? expectedSalary;
  final int? currentSalary;
  final int? noticePeriodDays;
  final bool willingToRelocate;
  final Map<String, dynamic>? preferredJobLocation;

  // Digital Presence
  final String linkedinUrl;
  final String githubUrl;
  final String portfolioUrl;

  // Structured Lists
  final List<dynamic>? skills;
  final List<dynamic>? languages;
  final List<dynamic>? educationHistory;
  final List<dynamic>? workExperience;
  final List<dynamic>? projects;
  final List<dynamic>? certifications;
  final List<dynamic>? achievements;
  final List<dynamic>? hobbies;
  final List<dynamic>? references;

  // Tracking
  final String acquisitionSource;

  User({
    this.id,
    required this.mobileNumber,
    this.whatsappNumber = '',
    required this.fullName,
    required this.email,
    required this.city,
    required this.goal,
    this.profileImageUrl,
    this.resumeData,
    this.profileCompletionScore = 0,
    
    this.state = '',
    this.pincode = '',
    this.country = 'India',
    this.address = '',
    this.dob,
    this.gender = '',
    this.maritalStatus = '',
    
    this.summary = '',
    this.yearsOfExperience = 0.0,
    this.expectedSalary,
    this.currentSalary,
    this.noticePeriodDays,
    this.willingToRelocate = false,
    this.preferredJobLocation,

    this.linkedinUrl = '',
    this.githubUrl = '',
    this.portfolioUrl = '',

    this.skills,
    this.languages,
    this.educationHistory,
    this.workExperience,
    this.projects,
    this.certifications,
    this.achievements,
    this.hobbies,
    this.references,

    this.acquisitionSource = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final studentProfile = json['student_profile'] as Map<String, dynamic>?;

    String getString(String? key1, [String? key2]) {
      var val1 = json[key1];
      if (val1 is Map) val1 = val1['name'];
      String str1 = val1?.toString().trim() ?? '';
      
      // Fix for previously cached stringified maps like {ID: ..., NAME: SOFTWARE ENGINEER}
      if (str1.startsWith('{') && str1.endsWith('}')) {
        final lowerStr1 = str1.toLowerCase();
        if (lowerStr1.contains('name:')) {
          final parts = str1.split(RegExp(r'name:', caseSensitive: false));
          if (parts.length > 1) {
            str1 = parts[1].replaceAll('}', '').trim();
          }
        }
      }
      
      if (str1.isNotEmpty) return str1;
      
      if (key2 != null) {
        var val2 = json[key2];
        if (val2 is Map) val2 = val2['name'];
        final str2 = val2?.toString().trim() ?? '';
        if (str2.isNotEmpty) return str2;
      }
      return '';
    }

    String getNestedString(String key) {
      final topLevel = getString(key);
      if (topLevel.isNotEmpty) return topLevel;
      
      var nested = studentProfile?[key];
      if (nested is Map) nested = nested['name'];
      String strNested = nested?.toString().trim() ?? '';
      
      if (strNested.startsWith('{') && strNested.endsWith('}')) {
        final lowerStr = strNested.toLowerCase();
        if (lowerStr.contains('name:')) {
          final parts = strNested.split(RegExp(r'name:', caseSensitive: false));
          if (parts.length > 1) {
            strNested = parts[1].replaceAll('}', '').trim();
          }
        }
      }
      
      return strNested;
    }

    return User(
      id: json['id'] as String?,
      mobileNumber: getString('mobile_number', 'mobileNumber'),
      whatsappNumber: getString('whatsapp_number', 'whatsappNumber').isEmpty ? getNestedString('whatsapp_number') : getString('whatsapp_number', 'whatsappNumber'),
      fullName: getString('full_name', 'fullName'),
      email: getString('email').isEmpty ? getNestedString('email') : getString('email'),
      city: getString('city').isEmpty ? getNestedString('city') : getString('city'),
      goal: getString('goal').isEmpty ? getNestedString('goal') : getString('goal'),
      profileImageUrl: json['profile_image_url'] ?? studentProfile?['profile_image_url'],
      resumeData: (json['resume_data'] ?? studentProfile?['resume_data']) as Map<String, dynamic>?,
      profileCompletionScore: json['profile_completion_score'] ?? studentProfile?['profile_completion_score'] ?? 0,
      
      state: getNestedString('state'),
      pincode: getNestedString('pincode'),
      country: getNestedString('country').isEmpty ? 'India' : getNestedString('country'),
      address: getNestedString('address'),
      dob: studentProfile?['dob'],
      gender: getNestedString('gender'),
      maritalStatus: getNestedString('marital_status'),
      
      summary: getNestedString('summary'),
      yearsOfExperience: (studentProfile?['years_of_experience'] ?? 0).toDouble(),
      expectedSalary: (json['expected_salary'] ?? studentProfile?['expected_salary']) as int?,
      currentSalary: (json['current_salary'] ?? studentProfile?['current_salary']) as int?,
      noticePeriodDays: (json['notice_period_days'] ?? studentProfile?['notice_period_days']) as int?,
      willingToRelocate: json['willing_to_relocate'] == 1 || json['willing_to_relocate'] == true || studentProfile?['willing_to_relocate'] == 1 || studentProfile?['willing_to_relocate'] == true,
      preferredJobLocation: (json['preferred_job_location'] ?? studentProfile?['preferred_job_location']) as Map<String, dynamic>?,

      linkedinUrl: getNestedString('linkedin_url'),
      githubUrl: getNestedString('github_url'),
      portfolioUrl: getNestedString('portfolio_url'),

      skills: (json['skills'] ?? studentProfile?['skills']) as List<dynamic>?,
      languages: (json['languages'] ?? studentProfile?['languages']) as List<dynamic>?,
      educationHistory: (json['education_history'] ?? studentProfile?['education_history']) as List<dynamic>?,
      workExperience: (json['work_experience'] ?? studentProfile?['work_experience']) as List<dynamic>?,
      projects: (json['projects'] ?? studentProfile?['projects']) as List<dynamic>?,
      certifications: (json['certifications'] ?? studentProfile?['certifications']) as List<dynamic>?,
      achievements: (json['achievements'] ?? studentProfile?['achievements']) as List<dynamic>?,
      hobbies: (json['hobbies'] ?? studentProfile?['hobbies']) as List<dynamic>?,
      references: (json['references'] ?? studentProfile?['references']) as List<dynamic>?,

      acquisitionSource: getNestedString('acquisition_source'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mobile_number': mobileNumber,
      'whatsapp_number': whatsappNumber,
      'full_name': fullName,
      'email': email,
      'city': city,
      'goal': goal,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (resumeData != null) 'resume_data': resumeData,
      'profile_completion_score': profileCompletionScore,
      
      'student_profile': {
        'state': state,
        'pincode': pincode,
        'country': country,
        'address': address,
        'dob': dob,
        'gender': gender,
        'marital_status': maritalStatus,
        
        'summary': summary,
        'years_of_experience': yearsOfExperience,
        'expected_salary': expectedSalary,
        'current_salary': currentSalary,
        'notice_period_days': noticePeriodDays,
        'willing_to_relocate': willingToRelocate,
        'preferred_job_location': preferredJobLocation,

        'linkedin_url': linkedinUrl,
        'github_url': githubUrl,
        'portfolio_url': portfolioUrl,

        'skills': skills,
        'languages': languages,
        'education_history': educationHistory,
        'work_experience': workExperience,
        'projects': projects,
        'certifications': certifications,
        'achievements': achievements,
        'hobbies': hobbies,
        'references': references,

        'acquisition_source': acquisitionSource,
      }
    };
  }
}
