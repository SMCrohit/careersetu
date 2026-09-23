import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/job_model.dart';
import '../domain/job_filter_state.dart';

class JobsRepository {
  final ApiClient _apiClient;

  JobsRepository(this._apiClient);

  Future<List<JobModel>> fetchJobs({
    int page = 1, 
    int limit = 10, 
    String query = '', 
    JobFilterState? filters,
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

    // Apply local filters
    if (filters != null) {
      if (filters.type != null && filters.type!.isNotEmpty) {
        allJobs = allJobs.where((job) => job.type == filters.type).toList();
      }
      if (filters.experience != null && filters.experience!.isNotEmpty) {
        allJobs = allJobs.where((job) => job.experience == filters.experience).toList();
      }
      if (filters.profession != null && filters.profession!.isNotEmpty) {
        allJobs = allJobs.where((job) => job.profession == filters.profession).toList();
      }
      if (filters.location != null && filters.location!.isNotEmpty) {
        final locQuery = filters.location!.toLowerCase();
        allJobs = allJobs.where((job) => job.location.toLowerCase().contains(locQuery)).toList();
      }
      if (filters.salary != null && filters.salary!.isNotEmpty) {
        final salQuery = filters.salary!.toLowerCase();
        allJobs = allJobs.where((job) => job.salary.toLowerCase().contains(salQuery)).toList();
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

