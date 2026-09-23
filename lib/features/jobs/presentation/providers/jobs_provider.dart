import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/jobs_repository.dart';
import '../../domain/job_model.dart';
import '../../domain/job_filter_state.dart';
import '../../../../core/api/api_client.dart';

class JobSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String value) => state = value;
}
final jobSearchQueryProvider = NotifierProvider<JobSearchQueryNotifier, String>(() => JobSearchQueryNotifier());

class JobFiltersNotifier extends Notifier<JobFilterState> {
  @override
  JobFilterState build() => JobFilterState();
  void updateFilters(JobFilterState value) => state = value;
  void clearFilters() => state = JobFilterState();
}
final jobFiltersProvider = NotifierProvider<JobFiltersNotifier, JobFilterState>(() => JobFiltersNotifier());

class JobsNotifier extends AsyncNotifier<List<JobModel>> {
  int _page = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  @override
  Future<List<JobModel>> build() async {
    _page = 1;
    final repo = ref.read(jobsRepositoryProvider);
    final query = ref.watch(jobSearchQueryProvider);
    final filters = ref.watch(jobFiltersProvider);
    
    final jobs = await repo.fetchJobs(page: _page, query: query, filters: filters);
    _hasMore = jobs.length == 10; // Default limit is 10
    return jobs;
  }

  Future<void> fetchMore() async {
    if (state.isLoading || _isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    // Tell UI to rebuild with isFetchingMore flag
    state = AsyncData(state.value ?? []);

    try {
      _page++;
      final repo = ref.read(jobsRepositoryProvider);
      final query = ref.read(jobSearchQueryProvider);
      final filters = ref.read(jobFiltersProvider);
      
      final newJobs = await repo.fetchJobs(page: _page, query: query, filters: filters);
      
      if (newJobs.isEmpty || newJobs.length < 10) {
        _hasMore = false;
      }
      
      final currentJobs = state.value ?? [];
      state = AsyncData([...currentJobs, ...newJobs]);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _isFetchingMore = false;
    }
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<JobModel>>(() {
  return JobsNotifier();
});

class AppliedJobsNotifier extends AsyncNotifier<List<JobModel>> {
  @override
  Future<List<JobModel>> build() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.get('/users/me/applications');
      // The API returns a list of JobApplication objects which have a nested `job`
      return (response.data as List).map((json) {
        if (json['job'] != null) {
          return JobModel.fromJson(json['job']);
        }
        return JobModel(
          id: json['job_id'] ?? '',
          title: 'Unknown Job',
          company: '',
          location: '',
          salary: '',
          type: '',
          level: '',
          description: '',
          requirements: [],
          postedTime: '',
          applicants: '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> applyJob(JobModel job) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.post('/users/me/applications', data: {
        'job_id': job.id,
        'status': 'applied',
      });
      if (state.value != null && !state.value!.any((j) => j.id == job.id)) {
        state = AsyncData([...state.value!, job]);
      }
    } catch (e) {
      // Handle implicitly
    }
  }
}

final appliedJobsProvider = AsyncNotifierProvider<AppliedJobsNotifier, List<JobModel>>(() {
  return AppliedJobsNotifier();
});
