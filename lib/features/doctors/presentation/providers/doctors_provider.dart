import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/doctor_model.dart';
import '../../data/doctors_repository.dart';

class DoctorSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String value) => state = value;
}

final doctorSearchQueryProvider = NotifierProvider<DoctorSearchQueryNotifier, String>(() => DoctorSearchQueryNotifier());

class DoctorsNotifier extends AsyncNotifier<List<Doctor>> {
  int _page = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  @override
  Future<List<Doctor>> build() async {
    _page = 1;
    _hasMore = true;
    _isFetchingMore = false;
    
    final repo = ref.watch(doctorsRepositoryProvider);
    final query = ref.watch(doctorSearchQueryProvider);
    
    final doctors = await repo.fetchDoctors(page: _page, query: query);
    _hasMore = doctors.length == 10;
    return doctors;
  }

  Future<void> fetchMore() async {
    if (state.isLoading || _isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    state = AsyncData(state.value ?? []);

    try {
      final repo = ref.read(doctorsRepositoryProvider);
      final query = ref.read(doctorSearchQueryProvider);
      
      _page++;
      final newDoctors = await repo.fetchDoctors(page: _page, query: query);
      
      if (newDoctors.isEmpty) {
        _hasMore = false;
        final currentDoctors = state.value ?? [];
        state = AsyncData([...currentDoctors]);
      } else {
        _hasMore = newDoctors.length == 10;
        final currentDoctors = state.value ?? [];
        state = AsyncData([...currentDoctors, ...newDoctors]);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final doctorsProvider = AsyncNotifierProvider<DoctorsNotifier, List<Doctor>>(() {
  return DoctorsNotifier();
});
