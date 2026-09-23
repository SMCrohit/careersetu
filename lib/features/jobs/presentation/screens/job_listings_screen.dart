import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/jobs_provider.dart';
import '../widgets/job_filter_bottom_sheet.dart';
import '../../domain/job_filter_state.dart';
import 'job_details_screen.dart';

class JobListingsScreen extends ConsumerStatefulWidget {
  const JobListingsScreen({super.key});

  @override
  ConsumerState<JobListingsScreen> createState() => _JobListingsScreenState();
}

class _JobListingsScreenState extends ConsumerState<JobListingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(jobsProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsyncValue = ref.watch(jobsProvider);

    final filters = ref.watch(jobFiltersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            onChanged: (val) => ref.read(jobSearchQueryProvider.notifier).updateQuery(val),
            decoration: InputDecoration(
              hintText: 'Search titles, zip code...',
              hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
              suffixIcon: IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.tune, color: AppColors.primaryBrand),
                    if (filters.type != null || filters.experience != null || filters.profession != null || filters.location != null || filters.salary != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _showFilterBottomSheet(context, filters),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppColors.white,
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Active filter chips
                  if (filters.type != null) _buildActiveFilterChip(filters.type!, () => ref.read(jobFiltersProvider.notifier).updateFilters(filters.copyWith(clearType: true))),
                  if (filters.experience != null) _buildActiveFilterChip(filters.experience!, () => ref.read(jobFiltersProvider.notifier).updateFilters(filters.copyWith(clearExperience: true))),
                  if (filters.profession != null) _buildActiveFilterChip(filters.profession!, () => ref.read(jobFiltersProvider.notifier).updateFilters(filters.copyWith(clearProfession: true))),
                  if (filters.location != null && filters.location!.isNotEmpty) _buildActiveFilterChip('Location: ${filters.location}', () => ref.read(jobFiltersProvider.notifier).updateFilters(filters.copyWith(clearLocation: true))),
                  if (filters.salary != null && filters.salary!.isNotEmpty) _buildActiveFilterChip('Salary: ${filters.salary}', () => ref.read(jobFiltersProvider.notifier).updateFilters(filters.copyWith(clearSalary: true))),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Expanded(
            child: jobsAsyncValue.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.refresh(jobsProvider.future);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Container(
                        height: MediaQuery.of(context).size.height - kToolbarHeight - 150,
                        alignment: Alignment.center,
                        child: const Text("No jobs found."),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.refresh(jobsProvider.future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length + (ref.read(jobsProvider.notifier).hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == jobs.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      
                      final job = jobs[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.business, color: AppColors.primaryBrand),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(child: Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryBrand))),
                                        if (job.createdDatetime != null && DateTime.now().difference(job.createdDatetime!).inDays <= 7)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBrand,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Text(
                                              'New',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(job.company, style: const TextStyle(fontSize: 14, color: AppColors.primaryText)),
                                    Text(job.location, style: const TextStyle(fontSize: 14, color: AppColors.secondaryText)),
                                    const SizedBox(height: 4),
                                    Text('${job.salary} • ${job.type}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text("Error: $e")),
            ),
          )
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, JobFilterState currentFilters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobFilterBottomSheet(
        initialFilters: currentFilters,
        onApply: (newFilters) {
          ref.read(jobFiltersProvider.notifier).updateFilters(newFilters);
        },
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF054C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
