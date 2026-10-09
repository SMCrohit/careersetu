import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/professionals_repository.dart';
import '../../domain/availability.dart';
import '../../domain/professional_filter_state.dart';
import '../../domain/professional_model.dart';

class ProfessionalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String value) => state = value.trim();
}

final professionalSearchQueryProvider = NotifierProvider<ProfessionalSearchQueryNotifier, String>(ProfessionalSearchQueryNotifier.new);

class ProfessionalFiltersNotifier extends Notifier<ProfessionalFilterState> {
  @override
  ProfessionalFilterState build() => const ProfessionalFilterState();
  void update(ProfessionalFilterState value) => state = value;
  void clear() => state = const ProfessionalFilterState();
}

final professionalFiltersProvider = NotifierProvider<ProfessionalFiltersNotifier, ProfessionalFilterState>(ProfessionalFiltersNotifier.new);

/// The listing screen's group (doctors or other professionals); null shows everyone.
class ListingGroupNotifier extends Notifier<ProfessionalGroup?> {
  @override
  ProfessionalGroup? build() => null;
  void set(ProfessionalGroup? value) => state = value;
}

final listingGroupProvider = NotifierProvider<ListingGroupNotifier, ProfessionalGroup?>(ListingGroupNotifier.new);

/// Paged list for the listing screen. Rebuilds from page 1 when search, filters or group change.
class ProfessionalsListNotifier extends AsyncNotifier<List<Professional>> {
  int _page = 1;
  int _total = 0;
  bool _isFetchingMore = false;

  int get total => _total;
  bool get hasMore => (state.value?.length ?? 0) < _total;

  @override
  Future<List<Professional>> build() async {
    _page = 1;
    final page = await ref.read(professionalsRepositoryProvider).fetchProfessionals(
          query: ref.watch(professionalSearchQueryProvider),
          filters: ref.watch(professionalFiltersProvider),
          group: ref.watch(listingGroupProvider),
        );
    _total = page.total;
    return page.items;
  }

  Future<void> fetchMore() async {
    if (state.isLoading || state.hasError || _isFetchingMore || !hasMore) return;
    _isFetchingMore = true;
    try {
      final page = await ref.read(professionalsRepositoryProvider).fetchProfessionals(
            page: _page + 1,
            query: ref.read(professionalSearchQueryProvider),
            filters: ref.read(professionalFiltersProvider),
            group: ref.read(listingGroupProvider),
          );
      _page++;
      _total = page.total;
      final known = {for (final p in state.value ?? <Professional>[]) p.id};
      state = AsyncData([...?state.value, ...page.items.where((p) => !known.contains(p.id))]);
    } catch (_) {
      // Keep what's loaded; scrolling again retries.
    } finally {
      _isFetchingMore = false;
    }
  }
}

final professionalsListProvider = AsyncNotifierProvider<ProfessionalsListNotifier, List<Professional>>(ProfessionalsListNotifier.new);

/// Up to 4 featured professionals for a Home section. Independent of the listing screen.
final featuredProfessionalsProvider = FutureProvider.family<List<Professional>, ProfessionalGroup>((ref, group) async {
  final page = await ref.read(professionalsRepositoryProvider).fetchProfessionals(limit: 4, group: group, featuredOnly: true);
  return page.items;
});

/// Fresh details for one professional.
final professionalDetailsProvider = FutureProvider.autoDispose.family<Professional, String>((ref, id) {
  return ref.read(professionalsRepositoryProvider).fetchProfessional(id);
});

/// Bookable dates and slots for one professional.
final professionalAvailabilityProvider = FutureProvider.autoDispose.family<List<AvailableDate>, String>((ref, id) {
  return ref.read(professionalsRepositoryProvider).fetchAvailability(id);
});

final professionalFilterOptionsProvider = FutureProvider.autoDispose<ProfessionalFilterOptions>((ref) {
  return ref.read(professionalsRepositoryProvider).fetchFilterOptions();
});
