import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/jobs_repository.dart';
import '../../domain/job_model.dart';

class JobSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String value) => state = value;
}
final jobSearchQueryProvider = NotifierProvider<JobSearchQueryNotifier, String>(() => JobSearchQueryNotifier());

class JobFiltersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void updateFilters(Set<String> value) => state = value;
}
final jobFiltersProvider = NotifierProvider<JobFiltersNotifier, Set<String>>(() => JobFiltersNotifier());

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

class AppliedJobsNotifier extends Notifier<List<JobModel>> {
  @override
  List<JobModel> build() {
    return [];
  }

  void applyJob(JobModel job) {
    if (!state.any((j) => j.id == job.id)) {
      state = [...state, job];
    }
  }
}

final appliedJobsProvider = NotifierProvider<AppliedJobsNotifier, List<JobModel>>(() {
  return AppliedJobsNotifier();
});
