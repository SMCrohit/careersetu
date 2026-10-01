import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/offers_repository.dart';
import '../../domain/offer_model.dart';

import '../../domain/offer_filter_state.dart';

class OfferFilterNotifier extends Notifier<OfferFilterState> {
  @override
  OfferFilterState build() => OfferFilterState();
  void updateFilters(OfferFilterState filters) => state = filters;
}

final offerFilterProvider = NotifierProvider<OfferFilterNotifier, OfferFilterState>(() {
  return OfferFilterNotifier();
});

final offerCitiesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(offersRepositoryProvider);
  return await repo.fetchOfferCities();
});

class OffersNotifier extends AsyncNotifier<List<OfferModel>> {
  int _skip = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  @override
  Future<List<OfferModel>> build() async {
    _skip = 0;
    final repo = ref.read(offersRepositoryProvider);
    final filters = ref.watch(offerFilterProvider);
    final offers = await repo.fetchOffers(city: filters.city, category: filters.category, skip: _skip, limit: _limit);
    _hasMore = offers.length == _limit;
    return offers;
  }

  Future<void> fetchMore() async {
    if (state.isLoading || _isFetchingMore || !_hasMore) return;
    _isFetchingMore = true;
    state = AsyncData(state.value ?? []);
    try {
      _skip += _limit;
      final repo = ref.read(offersRepositoryProvider);
      final filters = ref.read(offerFilterProvider);
      final newOffers = await repo.fetchOffers(city: filters.city, category: filters.category, skip: _skip, limit: _limit);
      if (newOffers.isEmpty || newOffers.length < _limit) {
        _hasMore = false;
      }
      final currentOffers = state.value ?? [];
      state = AsyncData([...currentOffers, ...newOffers]);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _isFetchingMore = false;
    }
  }
}

final offersProvider = AsyncNotifierProvider<OffersNotifier, List<OfferModel>>(() {
  return OffersNotifier();
});

class ClaimedOffersListNotifier extends AsyncNotifier<List<ClaimedOfferModel>> {
  int _skip = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  @override
  Future<List<ClaimedOfferModel>> build() async {
    _skip = 0;
    final repo = ref.read(offersRepositoryProvider);
    final claimed = await repo.fetchClaimedOffers(skip: _skip, limit: _limit);
    _hasMore = claimed.length == _limit;
    return claimed;
  }

  Future<void> fetchMore() async {
    if (state.isLoading || _isFetchingMore || !_hasMore) return;
    _isFetchingMore = true;
    state = AsyncData(state.value ?? []);
    try {
      _skip += _limit;
      final repo = ref.read(offersRepositoryProvider);
      final newClaimed = await repo.fetchClaimedOffers(skip: _skip, limit: _limit);
      if (newClaimed.isEmpty || newClaimed.length < _limit) {
        _hasMore = false;
      }
      final currentClaimed = state.value ?? [];
      state = AsyncData([...currentClaimed, ...newClaimed]);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> claim(String offerId) async {
    final repo = ref.read(offersRepositoryProvider);
    await repo.claimOffer(offerId);
    ref.invalidateSelf();
    ref.invalidate(offersProvider); // Refresh the local offers list
    await future;
  }
}

final claimedOffersListProvider = AsyncNotifierProvider<ClaimedOffersListNotifier, List<ClaimedOfferModel>>(() {
  return ClaimedOffersListNotifier();
});

class ScratchedRewardsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {};
  }

  void markAsScratched(String id) {
    state = {...state, id};
  }
}

final scratchedRewardsProvider = NotifierProvider<ScratchedRewardsNotifier, Set<String>>(() {
  return ScratchedRewardsNotifier();
});
