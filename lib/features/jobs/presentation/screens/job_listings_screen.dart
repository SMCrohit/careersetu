import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/job_filter_state.dart';
import '../providers/jobs_provider.dart';
import '../widgets/job_card.dart';
import '../widgets/job_filter_bottom_sheet.dart';
import 'applied_jobs_screen.dart';
import 'job_details_screen.dart';

/// Jobs tab: search, filters and the job list.
class JobListingsScreen extends ConsumerStatefulWidget {
  const JobListingsScreen({super.key});

  @override
  ConsumerState<JobListingsScreen> createState() => _JobListingsScreenState();
}

class _JobListingsScreenState extends ConsumerState<JobListingsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(jobSearchQueryProvider);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        ref.read(jobsProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => ref.read(jobSearchQueryProvider.notifier).updateQuery(value));
  }

  void _openFilters(JobFilterState current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobFilterBottomSheet(
        initialFilters: current,
        onApply: (f) => ref.read(jobFiltersProvider.notifier).updateFilters(f),
      ),
    );
  }

  void _clearAll() {
    _searchController.clear();
    ref.read(jobSearchQueryProvider.notifier).updateQuery('');
    ref.read(jobFiltersProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);
    final notifier = ref.read(jobsProvider.notifier);
    final filters = ref.watch(jobFiltersProvider);
    // Keep the applied list warm so cards and details know what was applied to.
    final appliedCount = ref.watch(appliedJobsProvider).value?.length ?? 0;

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Find your next job', style: AppText.screenTitle),
              const SizedBox(height: 2),
              Text(
                jobsAsync.hasValue ? '${notifier.total} ${notifier.total == 1 ? 'job' : 'jobs'} available' : 'Loading jobs…',
                style: AppText.label,
              ),
            ],
          ),
          actions: [
            _AppliedJobsButton(
              count: appliedCount,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppliedJobsScreen())),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            _buildSearchRow(filters),
            if (filters.activeCount > 0) _buildActiveFilters(filters),
            Expanded(
              child: RefreshIndicator(
                color: AppUi.accent,
                onRefresh: () {
                  ref.invalidate(appliedJobsProvider);
                  return ref.refresh(jobsProvider.future);
                },
                child: jobsAsync.when(
                  skipLoadingOnRefresh: true,
                  data: (jobs) => jobs.isEmpty
                      ? _buildMessage(
                          icon: Icons.search_off_rounded,
                          title: 'No jobs found',
                          subtitle: filters.activeCount > 0 || _searchController.text.isNotEmpty
                              ? 'Try removing some filters or searching for something else.'
                              : 'New jobs are posted regularly. Check back soon!',
                          action: filters.activeCount > 0 || _searchController.text.isNotEmpty ? ('Clear search & filters', _clearAll) : null,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: jobs.length + (notifier.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == jobs.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(color: AppUi.accent, strokeWidth: 2.5)),
                              );
                            }
                            final job = jobs[index];
                            return JobCard(
                              job: job,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job))),
                            );
                          },
                        ),
                  loading: () => ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: List.generate(4, (_) => const JobCardSkeleton()),
                  ),
                  error: (e, _) => _buildMessage(
                    icon: Icons.cloud_off_rounded,
                    title: "Couldn't load jobs",
                    subtitle: e is ApiException ? e.message : 'Please check your connection and try again.',
                    action: ('Try again', () => ref.invalidate(jobsProvider)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow(JobFilterState filters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: AppUi.card(radius: 14),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
                decoration: InputDecoration(
                  hintText: 'Search job title, company, skill…',
                  hintStyle: const TextStyle(color: AppColors.borderDark, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppUi.accent),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.secondaryText),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _openFilters(filters),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppUi.heroGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
                if (filters.activeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text('${filters.activeCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(JobFilterState f) {
    final n = ref.read(jobFiltersProvider.notifier);
    String lakh(int v) => '₹${(v / 100000).toStringAsFixed(v % 100000 == 0 ? 0 : 1)}L';
    final chips = <(String, VoidCallback)>[
      if (f.type != null) (f.type!, () => n.updateFilters(f.copyWith(clearType: true))),
      if (f.workModel != null) (f.workModel!, () => n.updateFilters(f.copyWith(clearWorkModel: true))),
      if (f.city != null) (f.city!, () => n.updateFilters(f.copyWith(clearCity: true))),
      if (f.experience != null) (f.experience!, () => n.updateFilters(f.copyWith(clearExperience: true))),
      if (f.hasSalary)
        (
          f.maxSalary != null ? '${lakh(f.minSalary ?? 0)} – ${lakh(f.maxSalary!)}' : '${lakh(f.minSalary ?? 0)}+',
          () => n.updateFilters(f.copyWith(clearSalary: true))
        ),
      if (f.postedWithinDays != null)
        (JobFilterState.postedOptions[f.postedWithinDays] ?? 'Recent', () => n.updateFilters(f.copyWith(clearPosted: true))),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final (label, onRemove) in chips)
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 6),
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppUi.accent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF0369A1)),
                  ),
                ],
              ),
            ),
          TextButton(onPressed: () => n.clearFilters(), child: const Text('Clear all')),
        ],
      ),
    );
  }

  Widget _buildMessage({required IconData icon, required String title, required String subtitle, (String, VoidCallback)? action}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 18),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.secondaryText, height: 1.4)),
        if (action != null) ...[
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton(
              onPressed: action.$2,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF1E3A8A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(action.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact app-bar button to Applied Jobs, with the number of applications.
class _AppliedJobsButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AppliedJobsButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: 'Applied jobs',
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppUi.cardShadow),
                child: const Icon(Icons.work_history_outlined, size: 20, color: AppColors.primaryText),
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppUi.accent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text('$count', textAlign: TextAlign.center, style: AppText.badge.copyWith(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
