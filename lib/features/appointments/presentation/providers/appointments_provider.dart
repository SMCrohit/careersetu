import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../professionals/presentation/providers/professionals_provider.dart';
import '../../domain/appointment_model.dart';

/// The student's appointments: upcoming first (soonest), then past.
class AppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final response = await ref.read(apiClientProvider).get('/users/me/appointments');
    return (response.data as List? ?? [])
        .whereType<Map>()
        .map((e) => Appointment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Books a slot. Throws [ApiException] with the server's reason (e.g. slot just filled).
  Future<Appointment> book({
    required String professionalId,
    required String isoDate,
    required String time,
    required String mode,
    String? notes,
  }) async {
    final response = await ref.read(apiClientProvider).post('/users/me/appointments', data: {
      'professional_id': professionalId,
      'appointment_date': isoDate,
      'appointment_time': time,
      'consultation_mode': mode,
      if (notes != null && notes.trim().isNotEmpty) 'notes_by_student': notes.trim(),
    });
    final appointment = Appointment.fromJson(Map<String, dynamic>.from(response.data));
    ref.invalidateSelf();
    ref.invalidate(professionalAvailabilityProvider(professionalId));
    return appointment;
  }

  /// Throws [ApiException] if the appointment can no longer be cancelled.
  Future<void> cancel(Appointment appointment, {String? reason}) async {
    await ref.read(apiClientProvider).delete(
      '/users/me/appointments/${appointment.id}',
      queryParameters: {if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim()},
    );
    ref.invalidateSelf();
    ref.invalidate(professionalAvailabilityProvider(appointment.professional.id));
  }
}

final appointmentsProvider = AsyncNotifierProvider<AppointmentsNotifier, List<Appointment>>(AppointmentsNotifier.new);
