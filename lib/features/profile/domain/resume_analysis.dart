class IdentityCheck {
  /// One of 'match', 'mismatch' or 'missing'.
  final String status;
  final String? profileValue;
  final String? resumeValue;

  IdentityCheck({required this.status, this.profileValue, this.resumeValue});

  bool get isMismatch => status == 'mismatch';

  factory IdentityCheck.fromJson(Map<String, dynamic> json) {
    return IdentityCheck(
      status: json['status']?.toString() ?? 'missing',
      profileValue: json['profile']?.toString(),
      resumeValue: json['resume']?.toString(),
    );
  }
}

class ResumeAnalysis {
  final bool isMatch;

  /// Keyed by 'name', 'email' and 'phone'.
  final Map<String, IdentityCheck> checks;

  /// Profile-shaped data read from the resume (same keys as `PUT /users/profile`).
  final Map<String, dynamic> extracted;

  ResumeAnalysis({required this.isMatch, required this.checks, required this.extracted});

  static const checkLabels = {'name': 'Name', 'email': 'Email', 'phone': 'Phone'};

  Map<String, IdentityCheck> get mismatches =>
      Map.fromEntries(checks.entries.where((e) => e.value.isMismatch));

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) {
    final rawChecks = Map<String, dynamic>.from(json['checks'] ?? {});
    return ResumeAnalysis(
      isMatch: json['is_match'] == true,
      checks: rawChecks.map((k, v) => MapEntry(k, IdentityCheck.fromJson(Map<String, dynamic>.from(v)))),
      extracted: Map<String, dynamic>.from(json['extracted'] ?? {}),
    );
  }
}
