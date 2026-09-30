import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/appointment_model.dart';
import '../../../professionals/domain/professional_model.dart';
import '../../../jobs/data/jobs_repository.dart'; // to get apiClientProvider

class AppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  int _skip = 0;
  final int _limit = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<Appointment>> build() async {
    _skip = 0;
    _hasMore = true;
    return _fetchAppointments(0, _limit);
  }

  Future<List<Appointment>> _fetchAppointments(int skip, int limit) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.get('/users/me/appointments?skip=$skip&limit=$limit');
      final list = (response.data as List).map((json) => Appointment.fromJson(json)).toList();
      if (list.length < limit) {
        _hasMore = false;
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _skip += _limit;

    try {
      final more = await _fetchAppointments(_skip, _limit);
      if (state.value != null) {
        state = AsyncData([...state.value!, ...more]);
      }
    } finally {
      _isLoadingMore = false;
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
