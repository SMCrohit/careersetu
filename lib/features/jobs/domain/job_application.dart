import 'package:flutter/material.dart';
import 'job_model.dart';

/// A job the student applied to, with its hiring status.
class JobApplication {
  final String id;

  /// applied, shortlisted, interview, hired, rejected (or anything new the admin sets).
  final String status;
  final DateTime? appliedAt;
  final DateTime? interviewAt;
  final String coverLetter;
  final String employerFeedback;
  final JobModel job;

  const JobApplication({
    required this.id,
    required this.status,
    required this.job,
    this.appliedAt,
    this.interviewAt,
    this.coverLetter = '',
    this.employerFeedback = '',
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    final jobJson = json['job'] is Map ? Map<String, dynamic>.from(json['job']) : <String, dynamic>{};
    return JobApplication(
      id: json['id']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'applied').toLowerCase(),
      appliedAt: DateTime.tryParse(json['applied_datetime']?.toString() ?? ''),
      interviewAt: DateTime.tryParse(json['interview_datetime']?.toString() ?? ''),
      coverLetter: json['cover_letter']?.toString() ?? '',
      employerFeedback: json['employer_feedback']?.toString() ?? '',
      job: jobJson.isNotEmpty
          ? JobModel.fromJson(jobJson).copyWith(hasApplied: true)
          : JobModel(id: json['job_id']?.toString() ?? '', title: 'Job no longer available', hasApplied: true),
    );
  }

  bool get isRejected => status == 'rejected';
  bool get isHired => status == 'hired';
  bool get isInterview => status.contains('interview');
  bool get isClosed => isRejected || isHired;

  /// Position on the Applied → Shortlisted → Interview → Hired track.
  int get stage {
    if (isHired) return 3;
    if (isInterview) return 2;
    if (status == 'shortlisted') return 1;
    return 0;
  }

  String get statusLabel => switch (status) {
        'applied' => 'Applied',
        'shortlisted' => 'Shortlisted',
        'rejected' => 'Not selected',
        'hired' => 'Hired 🎉',
        _ when isInterview => 'Interview',
        _ => status.isEmpty ? 'Applied' : '${status[0].toUpperCase()}${status.substring(1).replaceAll('_', ' ')}',
      };

  Color get statusColor => switch (stage) {
        _ when isRejected => const Color(0xFFDC2626),
        3 => const Color(0xFF059669),
        2 => const Color(0xFF7C3AED),
        1 => const Color(0xFFD97706),
        _ => const Color(0xFF0284C7),
      };
}
