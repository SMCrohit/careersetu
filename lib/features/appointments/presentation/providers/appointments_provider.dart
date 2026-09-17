import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/appointment_model.dart';
import '../../../professionals/domain/professional_model.dart';
import '../../../jobs/data/jobs_repository.dart'; // to get apiClientProvider

class AppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.get('/users/me/appointments');
      return (response.data as List).map((json) => Appointment.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> bookAppointment(Professional professional, String date, String time) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.post('/users/me/appointments', data: {
        'professional_id': professional.id,
        'appointment_date': date,
        'appointment_time': time,
        'status': 'pending',
      });
      final newAppt = Appointment.fromJson(response.data);
      if (state.value != null) {
        state = AsyncData([newAppt, ...state.value!]);
      }
    } catch (e) {
      // Handle error implicitly
    }
  }
}

final appointmentsProvider = AsyncNotifierProvider<AppointmentsNotifier, List<Appointment>>(() {
  return AppointmentsNotifier();
});
