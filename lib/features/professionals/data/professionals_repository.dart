import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/professional_model.dart';
import '../domain/professional_review_model.dart';
import '../../jobs/data/jobs_repository.dart'; // To reuse apiClientProvider

class ProfessionalsRepository {
  final ApiClient _apiClient;

  ProfessionalsRepository(this._apiClient);

  Future<List<Professional>> fetchProfessionals({int page = 1, int limit = 10, String query = '', String profession = 'All', String city = 'All'}) async {
    final skip = (page - 1) * limit;
    String url = '/professionals?skip=$skip&limit=$limit';
    if (query.isNotEmpty) url += '&search=$query';
    if (profession != 'All') url += '&profession=$profession';
    if (city != 'All') url += '&location_city=$city';

    final response = await _apiClient.get(url);
    final List<dynamic> data = response.data;
    
    return data.map((json) => Professional.fromJson(json)).toList();
  }

  Future<List<ProfessionalReview>> fetchReviews(String professionalId) async {
    final response = await _apiClient.get('/professionals/$professionalId/reviews');
    final List<dynamic> data = response.data;
    return data.map((json) => ProfessionalReview.fromJson(json)).toList();
  }

  Future<ProfessionalReview?> getMyReview(String professionalId) async {
    try {
      final response = await _apiClient.get('/users/me/professionals/$professionalId/review');
      return ProfessionalReview.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<ProfessionalReview> submitReview(String professionalId, double rating, String comment) async {
    final response = await _apiClient.post(
      '/users/me/professionals/$professionalId/review',
      data: {
        'rating': rating,
        'comment': comment,
      },
    );
    return ProfessionalReview.fromJson(response.data);
  }

  Future<List<String>> getBookedSlots(String professionalId, String date) async {
    try {
      final response = await _apiClient.get('/professionals/$professionalId/booked-slots?date=$date');
      return (response.data as List).map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }
}

final professionalsRepositoryProvider = Provider<ProfessionalsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfessionalsRepository(apiClient);
});
