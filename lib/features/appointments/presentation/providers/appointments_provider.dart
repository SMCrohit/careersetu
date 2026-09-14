import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/appointment_model.dart';
import '../../../doctors/domain/doctor_model.dart';

class AppointmentsNotifier extends Notifier<List<Appointment>> {
  @override
  List<Appointment> build() {
    // Return some mock past appointments
    return [
      Appointment(
        id: 'app_001',
        doctor: Doctor(
          id: 'doc_past_1',
          name: 'Dr. Neha Sharma',
          specialty: 'Clinical Psychologist',
          clinic: 'Mind Wellness Center',
          experienceYears: 8,
          rating: 4.8,
          reviews: 120,
          consultationFee: 1500,
          imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
        ),
        date: '10 Aug 2026',
        time: '02:00 PM',
        status: 'completed',
      ),
    ];
  }

  void bookAppointment(Doctor doctor, String date, String time) {
    final newAppt = Appointment(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      doctor: doctor,
      date: date,
      time: time,
      status: 'upcoming',
    );
    state = [newAppt, ...state];
  }
}

final appointmentsProvider = NotifierProvider<AppointmentsNotifier, List<Appointment>>(() {
  return AppointmentsNotifier();
});
