import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/jobs_provider.dart';
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
            decoration: const InputDecoration(
              hintText: 'Search titles, zip code...',
              hintStyle: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                  _buildFilterChip('Distance', filters.contains('Distance')),
                  _buildFilterChip('Salary', filters.contains('Salary')),
                  _buildFilterChip('Full-time', filters.contains('Full-time')),
                  _buildFilterChip('Experience', filters.contains('Experience')),
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
                                    Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        final currentFilters = ref.read(jobFiltersProvider);
        final newFilters = Set<String>.from(currentFilters);
        if (isSelected) {
          newFilters.remove(label);
        } else {
          newFilters.add(label);
        }
        ref.read(jobFiltersProvider.notifier).updateFilters(newFilters);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF054C1E) : AppColors.white,
          border: Border.all(color: isSelected ? const Color(0xFF054C1E) : AppColors.secondaryText),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
