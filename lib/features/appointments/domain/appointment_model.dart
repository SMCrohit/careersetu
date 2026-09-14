import '../../doctors/domain/doctor_model.dart';

class Appointment {
  final String id;
  final Doctor doctor;
  final String date;
  final String time;
  final String status; // 'upcoming', 'completed', 'cancelled'

  Appointment({
    required this.id,
    required this.doctor,
    required this.date,
    required this.time,
    required this.status,
  });
}
