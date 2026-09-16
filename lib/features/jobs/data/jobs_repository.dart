import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/job_model.dart';

class JobsRepository {
  final ApiClient _apiClient;

  JobsRepository(this._apiClient);

  Future<List<JobModel>> fetchJobs({
    int page = 1, 
    int limit = 10, 
    String query = '', 
    Set<String> filters = const {},
  }) async {
    final response = await _apiClient.get('/jobs');
    
    final List<dynamic> jobsJson = response.data;
    List<JobModel> allJobs = jobsJson.map((e) => JobModel.fromJson(e)).toList();
    
    // Apply search query locally (until backend supports query params)
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      allJobs = allJobs.where((job) {
        return job.title.toLowerCase().contains(q) || 
               job.company.toLowerCase().contains(q) ||
               job.location.toLowerCase().contains(q);
      }).toList();
    }

    // Apply simple mock filters locally
    if (filters.isNotEmpty) {
      if (filters.contains('Full-time')) {
        allJobs = allJobs.where((job) => job.type == 'Full-time').toList();
      }
      if (filters.contains('Distance')) {
        allJobs.sort((a, b) => a.location.compareTo(b.location));
      }
    }
    
    // Simulate pagination locally
    final startIndex = (page - 1) * limit;
    if (startIndex >= allJobs.length) {
      return [];
    }
    
    final endIndex = (startIndex + limit) > allJobs.length 
        ? allJobs.length 
        : (startIndex + limit);
        
    return allJobs.sublist(startIndex, endIndex);
  }
}

final apiClientProvider = Provider((ref) => ApiClient());

final jobsRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return JobsRepository(apiClient);
});

