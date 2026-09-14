import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/offers_repository.dart';
import '../../domain/offer_model.dart';

final offersProvider = FutureProvider<List<OfferModel>>((ref) async {
  final repo = ref.read(offersRepositoryProvider);
  return await repo.fetchOffers();
});

class ClaimedOffersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {};
  }

  void claimOffer(String id) {
    state = {...state, id};
  }
}

final claimedOffersProvider = NotifierProvider<ClaimedOffersNotifier, Set<String>>(() {
  return ClaimedOffersNotifier();
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
