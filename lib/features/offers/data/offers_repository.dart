import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/offer_model.dart';
import '../../jobs/data/jobs_repository.dart'; // To reuse apiClientProvider

class OffersRepository {
  final ApiClient _apiClient;

  OffersRepository(this._apiClient);

  Future<List<OfferModel>> fetchOffers() async {
    final response = await _apiClient.get('/offers');
    final List<dynamic> offersJson = response.data;
    return offersJson.map((e) => OfferModel.fromJson(e)).toList();
  }
}

final offersRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OffersRepository(apiClient);
});
