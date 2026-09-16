import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/doctor_model.dart';
import '../../jobs/data/jobs_repository.dart'; // To reuse apiClientProvider

class DoctorsRepository {
  final ApiClient _apiClient;

  DoctorsRepository(this._apiClient);

  Future<List<Doctor>> fetchDoctors({int page = 1, int limit = 10, String query = ''}) async {
    final response = await _apiClient.get('/doctors');
    final List<dynamic> data = response.data;
    
    List<Doctor> allDoctors = data.map((json) => Doctor.fromJson(json)).toList();

    // Filter by query locally until backend supports it
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      allDoctors = allDoctors.where((d) => 
        d.name.toLowerCase().contains(q) || 
        d.specialty.toLowerCase().contains(q) ||
        d.clinic.toLowerCase().contains(q)
      ).toList();
    }

    // Pagination locally until backend supports it
    final startIndex = (page - 1) * limit;
    if (startIndex >= allDoctors.length) {
      return [];
    }

    final endIndex = (startIndex + limit) > allDoctors.length ? allDoctors.length : (startIndex + limit);
    return allDoctors.sublist(startIndex, endIndex);
  }
}

final doctorsRepositoryProvider = Provider<DoctorsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DoctorsRepository(apiClient);
});
