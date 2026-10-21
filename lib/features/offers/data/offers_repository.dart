import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/offer_model.dart';

class OffersRepository {
  final ApiClient _apiClient;

  OffersRepository(this._apiClient);

  Future<List<String>> fetchOfferCities() async {
    final response = await _apiClient.get('/offers/cities');
    final List<dynamic> cities = response.data;
    return cities.map((e) => e.toString()).toList();
  }

  Future<List<String>> fetchOfferProfessions() async {
    final response = await _apiClient.get('/goals');
    final List<dynamic> goals = response.data;
    return goals.map((e) => e['name'].toString()).toList();
  }

  Future<List<OfferModel>> fetchOffers({
    String? city,
    String? category,
    String? redemptionType,
    List<String>? professions,
    String? validityUpto,
    String? stream,
    int skip = 0,
    int limit = 30,
  }) async {
    final queryParameters = <String, dynamic>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (city != null && city.isNotEmpty && city.toLowerCase() != 'all') {
      queryParameters['city'] = city;
    }
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      queryParameters['category'] = category;
    }
    if (redemptionType != null && redemptionType.isNotEmpty && redemptionType.toLowerCase() != 'all') {
      queryParameters['redemption_type'] = redemptionType;
    }
    if (professions != null && professions.isNotEmpty) {
      queryParameters['professions'] = professions.join(',');
    }
    if (validityUpto != null && validityUpto.isNotEmpty) {
      queryParameters['validity_upto'] = validityUpto;
    }
    if (stream != null && stream.isNotEmpty && stream.toLowerCase() != 'all') {
      queryParameters['stream'] = stream;
    }
    
    final response = await _apiClient.get(
      '/offers', 
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null
    );
    final List<dynamic> offersJson = response.data;
    return offersJson.map((e) => OfferModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> claimOffer(String offerId, {Map<String, dynamic>? inquiryDetails}) async {
    final data = inquiryDetails != null ? {'inquiry_details': inquiryDetails} : null;
    final response = await _apiClient.post('/offers/$offerId/claim', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> redeemClaimedOffer(String claimedId) async {
    await _apiClient.post('/offers/claimed/$claimedId/redeem');
  }

  Future<List<ClaimedOfferModel>> fetchClaimedOffers({int skip = 0, int limit = 50}) async {
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
