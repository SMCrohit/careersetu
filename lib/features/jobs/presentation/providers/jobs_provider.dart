import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/jobs_repository.dart';
import '../../domain/job_application.dart';
import '../../domain/job_filter_state.dart';
import '../../domain/job_model.dart';

class JobSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String value) => state = value.trim();
}

final jobSearchQueryProvider = NotifierProvider<JobSearchQueryNotifier, String>(JobSearchQueryNotifier.new);

class JobFiltersNotifier extends Notifier<JobFilterState> {
  @override
  JobFilterState build() => const JobFilterState();
  void updateFilters(JobFilterState value) => state = value;
  void clearFilters() => state = const JobFilterState();
}

final jobFiltersProvider = NotifierProvider<JobFiltersNotifier, JobFilterState>(JobFiltersNotifier.new);

/// Paged job list from the server. Rebuilds from page 1 when the search or filters change.
class JobsNotifier extends AsyncNotifier<List<JobModel>> {
  int _page = 1;
  int _total = 0;
  bool _isFetchingMore = false;

  int get total => _total;
  bool get hasMore => (state.value?.length ?? 0) < _total;
  bool get isFetchingMore => _isFetchingMore;

  @override
  Future<List<JobModel>> build() async {
    _page = 1;
    final result = await ref.read(jobsRepositoryProvider).fetchJobs(
          query: ref.watch(jobSearchQueryProvider),
          filters: ref.watch(jobFiltersProvider),
        );
    _total = result.total;
    return result.jobs;
  }

  Future<void> fetchMore() async {
    if (state.isLoading || state.hasError || _isFetchingMore || !hasMore) return;
    _isFetchingMore = true;
    state = AsyncData(state.value ?? []);
    try {
      final result = await ref.read(jobsRepositoryProvider).fetchJobs(
            page: _page + 1,
            query: ref.read(jobSearchQueryProvider),
            filters: ref.read(jobFiltersProvider),
          );
      _page++;
      _total = result.total;
      final known = {for (final j in state.value ?? <JobModel>[]) j.id};
      state = AsyncData([...?state.value, ...result.jobs.where((j) => !known.contains(j.id))]);
    } catch (_) {
      // Keep what's loaded; scrolling again retries.
      state = AsyncData(state.value ?? []);
    } finally {
      _isFetchingMore = false;
    }
  }

  void markApplied(String jobId) {
    final jobs = state.value;
    if (jobs == null) return;
    state = AsyncData([
      for (final j in jobs) j.id == jobId ? j.copyWith(hasApplied: true, applicantsCount: j.applicantsCount + 1) : j,
    ]);
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<JobModel>>(JobsNotifier.new);

/// The student's applications, newest first.
class AppliedJobsNotifier extends AsyncNotifier<List<JobApplication>> {
  @override
  Future<List<JobApplication>> build() => ref.read(jobsRepositoryProvider).fetchApplications();

  JobApplication? applicationFor(String jobId) {
    for (final a in state.value ?? <JobApplication>[]) {
      if (a.job.id == jobId) return a;
    }
    return null;
  }

  /// Submits an application. Throws [ApiException] with a user-facing message on failure.
  Future<JobApplication> apply(JobModel job, {String? coverLetter, Map<String, String> screeningResponses = const {}}) async {
    try {
      final application = await ref.read(jobsRepositoryProvider).apply(
            job.id,
            coverLetter: coverLetter,
            screeningResponses: screeningResponses,
          );
      state = AsyncData([application, ...?state.value?.where((a) => a.job.id != job.id)]);
      ref.read(jobsProvider.notifier).markApplied(job.id);
      return application;
    } on ApiException catch (e) {
      // Already applied (e.g. from another device): sync the list so the UI shows it.
      if (e.statusCode == 409) {
        ref.invalidateSelf();
        ref.read(jobsProvider.notifier).markApplied(job.id);
      }
      rethrow;
    }
  }
}

final appliedJobsProvider = AsyncNotifierProvider<AppliedJobsNotifier, List<JobApplication>>(AppliedJobsNotifier.new);

/// One job, refreshed from the server (used by the details screen).
final jobDetailsProvider = FutureProvider.autoDispose.family<JobModel, String>((ref, id) {
  return ref.read(jobsRepositoryProvider).fetchJob(id);
});

final jobFilterOptionsProvider = FutureProvider.autoDispose<JobFilterOptions>((ref) {
  return ref.read(jobsRepositoryProvider).fetchFilterOptions();
});
