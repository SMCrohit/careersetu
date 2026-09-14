import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/job_model.dart';
import '../providers/jobs_provider.dart';

class JobDetailsScreen extends ConsumerWidget {
  final JobModel job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Job Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.white,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.business, size: 32, color: AppColors.primaryBrand),
                      ),
                      Text(job.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
                      const SizedBox(height: 4),
                      Text('${job.company} • ${job.location.split('(')[0].trim()}', style: const TextStyle(fontSize: 16, color: AppColors.primaryText)),
                      const SizedBox(height: 4),
                      Text('${job.postedTime} • ${job.applicants}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTag(Icons.work, job.type),
                          const SizedBox(width: 8),
                          _buildTag(null, job.level),
                        ],
                      )
                    ],
                  ),
                ),
                
                Container(
                  width: double.infinity,
                  color: AppColors.white,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About the job', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text(job.description, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Text('Requirements', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      ...job.requirements.map((req) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                            Expanded(child: Text(req, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.5))),
                          ],
                        ),
                      ))
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  color: AppColors.white,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text(job.location, style: Theme.of(context).textTheme.bodyMedium),
                      Container(
                        width: double.infinity,
                        height: 150,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('Map View Placeholder', style: TextStyle(color: AppColors.secondaryText))),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PrimaryButton(
                    text: 'Apply Now',
                    onPressed: () {
                      ref.read(appliedJobsProvider.notifier).applyJob(job);
                      CustomToast.showSuccess(context, 'Application submitted to ${job.company}!');
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTag(IconData? icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.secondaryText),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.secondaryText),
            const SizedBox(width: 4),
          ],
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
