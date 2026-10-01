import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/offer_model.dart';
import '../../jobs/data/jobs_repository.dart'; // To reuse apiClientProvider

class OffersRepository {
  final ApiClient _apiClient;

  OffersRepository(this._apiClient);

  Future<List<String>> fetchOfferCities() async {
    final response = await _apiClient.get('/offers/cities');
    final List<dynamic> cities = response.data;
    return cities.map((e) => e.toString()).toList();
  }

  Future<List<OfferModel>> fetchOffers({String? city, String? category, int skip = 0, int limit = 20}) async {
    final queryParameters = <String, dynamic>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (city != null) queryParameters['city'] = city;
    if (category != null) queryParameters['category'] = category;
    
    final response = await _apiClient.get(
      '/offers', 
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null
    );
    final List<dynamic> offersJson = response.data;
    return offersJson.map((e) => OfferModel.fromJson(e)).toList();
  }

  Future<String> claimOffer(String offerId) async {
    final response = await _apiClient.post('/offers/$offerId/claim');
    return response.data['discount_code'] ?? '';
  }

  Future<List<ClaimedOfferModel>> fetchClaimedOffers({int skip = 0, int limit = 20}) async {
    final response = await _apiClient.get(
      '/users/me/claimed-offers',
      queryParameters: {'skip': skip.toString(), 'limit': limit.toString()},
    );
    final List<dynamic> claimedJson = response.data;
    return claimedJson.map((e) => ClaimedOfferModel.fromJson(e)).toList();
  }
}

final offersRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OffersRepository(apiClient);
});
