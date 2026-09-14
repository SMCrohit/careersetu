import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/jobs_provider.dart';
import 'job_details_screen.dart';

class AppliedJobsScreen extends ConsumerWidget {
  const AppliedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliedJobs = ref.watch(appliedJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Jobs', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryBrand),
      ),
      body: appliedJobs.isEmpty
          ? const Center(child: Text("You haven't applied to any jobs yet."))
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              itemCount: appliedJobs.length,
              itemBuilder: (context, index) {
                final job = appliedJobs[index];
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
  }
}
