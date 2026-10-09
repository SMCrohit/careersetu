import 'package:flutter/material.dart';
import '../../professionals/domain/professional_model.dart';

class Appointment {
  final String id;
  final Professional professional;
  final DateTime? date;

  /// "02:00 PM".
  final String time;

  /// Raw status from the server (pending, sent_to_doctor, completed, cancelled).
  final String status;

  /// What to show: pending, confirmed, completed, cancelled, missed or expired.
  final String displayStatus;
  final String consultationMode;
  final String? notesByStudent;
  final String? cancellationReason;
  final bool canCancel;
  final bool canReview;

  const Appointment({
    required this.id,
    required this.professional,
    required this.date,
    required this.time,
    required this.status,
    required this.displayStatus,
    required this.consultationMode,
    this.notesByStudent,
    this.cancellationReason,
    this.canCancel = false,
    this.canReview = false,
  });

  bool get isUpcoming => displayStatus == 'pending' || displayStatus == 'confirmed';
  bool get isCancelled => displayStatus == 'cancelled';
  bool get isPast => !isUpcoming && !isCancelled;

  String get statusLabel => switch (displayStatus) {
        'pending' => 'Awaiting confirmation',
        'confirmed' => 'Confirmed',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        'missed' => 'Missed',
        'expired' => 'Not confirmed',
        _ => displayStatus,
      };

  Color get statusColor => switch (displayStatus) {
        'pending' => const Color(0xFFD97706),
        'confirmed' => const Color(0xFF0284C7),
        'completed' => const Color(0xFF059669),
        'missed' => const Color(0xFFDC2626),
        _ => const Color(0xFF64748B),
      };

  IconData get modeIcon => switch (consultationMode.toLowerCase()) {
        'online' => Icons.videocam_outlined,
        'phone' => Icons.call_outlined,
        _ => Icons.location_on_outlined,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'pending';
    return Appointment(
      id: json['id']?.toString() ?? '',
      professional: json['professional'] is Map
          ? Professional.fromJson(Map<String, dynamic>.from(json['professional']))
          : Professional(
              id: json['professional_id']?.toString() ?? '',
              name: 'Professional',
              profession: '',
              specialty: '',
              clinic: '',
              experienceYears: 0,
              experienceString: '',
              rating: 0,
              defaultRating: 0,
              reviews: 0,
              consultationFee: 0,
            ),
      date: DateTime.tryParse(json['appointment_date']?.toString() ?? ''),
      time: json['appointment_time']?.toString() ?? '',
      status: status,
      displayStatus: json['display_status']?.toString() ?? status,
      consultationMode: json['consultation_mode']?.toString() ?? 'In-Person',
      notesByStudent: json['notes_by_student']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      canCancel: json['can_cancel'] == true,
      canReview: json['can_review'] == true,
    );
  }
}
