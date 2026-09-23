import '../../professionals/domain/professional_model.dart';

class Appointment {
  final String id;
  final Professional professional;
  final String date;
  final String time;
  final String status; // 'upcoming', 'completed', 'cancelled'

  Appointment({
    required this.id,
    required this.professional,
    required this.date,
    required this.time,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      professional: json['professional'] != null
          ? Professional.fromJson(json['professional'])
          : Professional(
              id: json['professional_id']?.toString() ?? '',
              name: 'Unknown Professional',
              profession: 'Professional',
              specialty: '',
              clinic: '',
              experienceYears: 0,
              rating: 0,
              defaultRating: 0,
              reviews: 0,
              consultationFee: 0,
            ),
      date: json['appointment_date'] ?? '',
      time: json['appointment_time'] ?? '',
      status: json['status'] ?? 'upcoming',
    );
  }
}
