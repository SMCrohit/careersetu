import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/job_model.dart';

/// Company initial on the soft-blue tile used by Home cards.
class CompanyAvatar extends StatelessWidget {
  final JobModel job;
  final double size;

  const CompanyAvatar({super.key, required this.job, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppUi.softBlue,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFFE3F1FF)),
      ),
      alignment: Alignment.center,
      child: Text(
        job.initial,
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w600, color: AppColors.primaryBrand),
      ),
    );
  }
}

/// Small rounded label, e.g. "Full-time" or "Remote".
class JobPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const JobPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppUi.softBlue, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppUi.accent),
          const SizedBox(width: 4),
          Text(label, style: AppText.chip),
        ],
      ),
    );
  }
}

/// Status badge in the card corner: Applied, Featured or New.
class JobBadge extends StatelessWidget {
  final JobModel job;

  const JobBadge({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    if (job.hasApplied) {
      return _badge('Applied', Icons.check_circle, const Color(0xFF059669), const Color(0xFFD1FAE5));
    }
    if (job.isFeatured) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(gradient: AppUi.heroGradient, borderRadius: BorderRadius.circular(20)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 12, color: Color(0xFFFCD34D)),
            SizedBox(width: 3),
            Text('Featured', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      );
    }
    if (job.isNew) {
      return _badge('New', Icons.fiber_new_rounded, const Color(0xFF0284C7), const Color(0xFFE0F2FE));
    }
    return const SizedBox.shrink();
  }

  Widget _badge(String text, IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

/// A job in the list.
class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppUi.cardShadow,
        border: job.isFeatured ? Border.all(color: const Color(0xFF93C5FD)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanyAvatar(job: job),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.cardTitle),
                          const SizedBox(height: 3),
                          Text(job.companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.subtitle),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    JobBadge(job: job),
                  ],
                ),
                if (job.location.short.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(job.location.short,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (job.jobType.isNotEmpty) JobPill(icon: Icons.schedule_rounded, label: job.jobType),
                    if (job.workModel.isNotEmpty) JobPill(icon: Icons.apartment_rounded, label: job.workModel),
                    JobPill(icon: Icons.trending_up_rounded, label: job.experienceLabel),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(job.salaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: job.salaryLabel == 'Not disclosed' ? AppColors.secondaryText : AppColors.primaryText,
                          )),
                    ),
                    if (job.postedAgo.isNotEmpty)
                      Text(job.postedAgo, style: AppText.label),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey placeholder card shown while jobs load.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: const Color(0xFFEEF2F7), borderRadius: BorderRadius.circular(6)),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppUi.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            bar(48, 48),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(160, 14), const SizedBox(height: 8), bar(100, 12)]),
          ]),
          const SizedBox(height: 14),
          Row(children: [bar(70, 22), const SizedBox(width: 6), bar(60, 22), const SizedBox(width: 6), bar(55, 22)]),
          const SizedBox(height: 14),
          bar(130, 14),
        ],
      ),
    );
  }
}
