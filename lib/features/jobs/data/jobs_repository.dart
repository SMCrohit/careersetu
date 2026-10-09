import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/job_application.dart';
import '../domain/job_filter_state.dart';
import '../domain/job_model.dart';

// Kept here as well so existing imports of `apiClientProvider` from this file keep working.
export '../../../core/api/api_client.dart' show apiClientProvider;

class JobsPage {
  final List<JobModel> jobs;
  final int total;

  const JobsPage(this.jobs, this.total);
}

class JobFilterOptions {
  final List<String> cities;
  final List<String> jobTypes;
  final List<String> workModels;

  const JobFilterOptions({this.cities = const [], this.jobTypes = const [], this.workModels = const []});
}

class JobsRepository {
  final ApiClient _apiClient;

  JobsRepository(this._apiClient);

  static const pageSize = 10;

  Future<JobsPage> fetchJobs({int page = 1, String query = '', JobFilterState filters = const JobFilterState()}) async {
    final response = await _apiClient.get('/jobs', queryParameters: {
      'page': page,
      'limit': pageSize,
      if (query.trim().isNotEmpty) 'search': query.trim(),
      ...filters.toQuery(),
    });
    final data = Map<String, dynamic>.from(response.data);
    final jobs = (data['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return JobsPage(jobs, (data['total'] as num?)?.toInt() ?? jobs.length);
  }

  Future<JobModel> fetchJob(String id) async {
    final response = await _apiClient.get('/jobs/$id');
    return JobModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<JobFilterOptions> fetchFilterOptions() async {
    final response = await _apiClient.get('/jobs/filters');
    final data = Map<String, dynamic>.from(response.data);
    List<String> list(String key) => (data[key] as List? ?? []).map((e) => e.toString()).toList();
    return JobFilterOptions(cities: list('cities'), jobTypes: list('job_types'), workModels: list('work_models'));
  }

  Future<List<JobApplication>> fetchApplications() async {
    final response = await _apiClient.get('/users/me/applications');
    return (response.data as List? ?? [])
        .whereType<Map>()
        .map((e) => JobApplication.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Throws [ApiException] with the server's message (e.g. already applied, cover letter required).
  Future<JobApplication> apply(String jobId, {String? coverLetter, Map<String, String> screeningResponses = const {}}) async {
    final response = await _apiClient.post('/users/me/applications', data: {
      'job_id': jobId,
      if (coverLetter != null && coverLetter.trim().isNotEmpty) 'cover_letter': coverLetter.trim(),
      'screening_responses': screeningResponses,
    });
    return JobApplication.fromJson(Map<String, dynamic>.from(response.data));
  }
}

final jobsRepositoryProvider = Provider((ref) => JobsRepository(ref.watch(apiClientProvider)));
