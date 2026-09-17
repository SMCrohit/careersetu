import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/professional_model.dart';
import '../../jobs/data/jobs_repository.dart'; // To reuse apiClientProvider

class ProfessionalsRepository {
  final ApiClient _apiClient;

  ProfessionalsRepository(this._apiClient);

  Future<List<Professional>> fetchProfessionals({int page = 1, int limit = 10, String query = ''}) async {
    final response = await _apiClient.get('/professionals');
    final List<dynamic> data = response.data;
    
    List<Professional> allProfessionals = data.map((json) => Professional.fromJson(json)).toList();

    // Filter by query locally until backend supports it
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      allProfessionals = allProfessionals.where((d) => 
        d.name.toLowerCase().contains(q) || 
        d.specialty.toLowerCase().contains(q) ||
        d.clinic.toLowerCase().contains(q)
      ).toList();
    }

    // Pagination locally until backend supports it
    final startIndex = (page - 1) * limit;
    if (startIndex >= allProfessionals.length) {
      return [];
    }

    final endIndex = (startIndex + limit) > allProfessionals.length ? allProfessionals.length : (startIndex + limit);
    return allProfessionals.sublist(startIndex, endIndex);
  }
}

final professionalsRepositoryProvider = Provider<ProfessionalsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfessionalsRepository(apiClient);
});
