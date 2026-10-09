import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/job_application.dart';
import 'job_card.dart';

/// An application in "Applied Jobs": the job, its status and progress.
class AppliedJobCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;

  const AppliedJobCard({super.key, required this.application, required this.onTap});

  static const _steps = ['Applied', 'Shortlisted', 'Interview', 'Hired'];

  @override
  Widget build(BuildContext context) {
    final a = application;
    final job = a.job;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppUi.card(),
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
                    CompanyAvatar(job: job, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                          const SizedBox(height: 2),
                          Text([job.companyName, job.location.city].where((e) => e.isNotEmpty).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: a.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(a.statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: a.statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (a.isRejected)
                  _note(Icons.info_outline, "The employer didn't move forward this time. Keep applying!", AppColors.error)
                else
                  _progress(a),
                if (a.interviewAt != null && !a.isClosed) ...[
                  const SizedBox(height: 10),
                  _note(Icons.event_available_rounded,
                      'Interview on ${DateFormat('d MMM yyyy, h:mm a').format(a.interviewAt!.toLocal())}', const Color(0xFF7C3AED)),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.borderDark),
                    const SizedBox(width: 5),
                    Text(a.appliedAt != null ? 'Applied on ${DateFormat('d MMM yyyy').format(a.appliedAt!.toLocal())}' : 'Applied',
                        style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                    const Spacer(),
                    Text(job.salaryLabel,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progress(JobApplication a) {
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: i <= a.stage ? AppUi.accentGradient : null,
                    color: i <= a.stage ? null : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_steps[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == a.stage ? FontWeight.w600 : FontWeight.w500,
                      color: i <= a.stage ? AppColors.primaryBrand : AppColors.borderDark,
                    )),
              ],
            ),
          ),
          if (i < _steps.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }

  Widget _note(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
