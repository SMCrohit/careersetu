import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/professional_model.dart';
import '../../data/professionals_repository.dart';

class ProfessionalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String value) => state = value;
}

final professionalSearchQueryProvider = NotifierProvider<ProfessionalSearchQueryNotifier, String>(() => ProfessionalSearchQueryNotifier());

class ProfessionalFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void updateFilter(String value) => state = value;
}

final professionFilterProvider = NotifierProvider<ProfessionalFilterNotifier, String>(() => ProfessionalFilterNotifier());

class CityFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void updateFilter(String value) => state = value;
}

final cityFilterProvider = NotifierProvider<CityFilterNotifier, String>(() => CityFilterNotifier());

class ProfessionalsNotifier extends AsyncNotifier<List<Professional>> {
  int _page = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  @override
  Future<List<Professional>> build() async {
    _page = 1;
    _hasMore = true;
    _isFetchingMore = false;
    
    final repo = ref.watch(professionalsRepositoryProvider);
    final query = ref.watch(professionalSearchQueryProvider);
    final profession = ref.watch(professionFilterProvider);
    final city = ref.watch(cityFilterProvider);
    
    final professionals = await repo.fetchProfessionals(page: _page, query: query, profession: profession, city: city);
    _hasMore = professionals.length == 10;
    return professionals;
  }

  Future<void> fetchMore() async {
    if (state.isLoading || _isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    state = AsyncData(state.value ?? []);

    try {
      final repo = ref.read(professionalsRepositoryProvider);
      final query = ref.read(professionalSearchQueryProvider);
      final profession = ref.read(professionFilterProvider);
      final city = ref.read(cityFilterProvider);
      
      _page++;
      final newProfessionals = await repo.fetchProfessionals(page: _page, query: query, profession: profession, city: city);
      
      if (newProfessionals.isEmpty) {
        _hasMore = false;
        final currentProfessionals = state.value ?? [];
        state = AsyncData([...currentProfessionals]);
      } else {
        _hasMore = newProfessionals.length == 10;
        final currentProfessionals = state.value ?? [];
        state = AsyncData([...currentProfessionals, ...newProfessionals]);
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

final professionalsProvider = AsyncNotifierProvider<ProfessionalsNotifier, List<Professional>>(() {
  return ProfessionalsNotifier();
});
