import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/job_model.dart';
import '../providers/jobs_provider.dart';
import '../widgets/apply_job_sheet.dart';
import '../widgets/job_card.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final JobModel job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  bool _applying = false;

  Future<void> _applyInApp(JobModel job) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApplyJobSheet(job: job),
    );
    if (submitted == true && mounted) {
      CustomToast.showSuccess(context, 'Application sent to ${job.companyName.isNotEmpty ? job.companyName : 'the employer'}!');
    }
  }

  Future<void> _applyExternal(JobModel job) async {
    final uri = Uri.tryParse(job.externalApplyUrl.startsWith('http') ? job.externalApplyUrl : 'https://${job.externalApplyUrl}');
    if (uri == null) {
      CustomToast.showError(context, 'This job has an invalid application link.');
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Apply on company site'),
        content: Text(
            "You'll finish your application on ${uri.host}. We'll add this job to your Applied Jobs so you can keep track of it."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (go != true || !mounted) return;

    setState(() => _applying = true);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      if (mounted) {
        setState(() => _applying = false);
        CustomToast.showError(context, "Couldn't open the application link.");
      }
      return;
    }
    try {
      await ref.read(appliedJobsProvider.notifier).apply(job);
      if (mounted) CustomToast.showSuccess(context, 'Added to your Applied Jobs');
    } on ApiException catch (e) {
      if (mounted && e.statusCode != 409) CustomToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fresh copy from the server; fall back to the list's copy while loading or if it fails.
    final details = ref.watch(jobDetailsProvider(widget.job.id));
    final job = details.value ?? widget.job;
    final application = ref.watch(appliedJobsProvider.select((s) => s.value?.where((a) => a.job.id == job.id).firstOrNull));
    final hasApplied = job.hasApplied || application != null;
    final unavailable = details.hasError && details.error is ApiException && (details.error as ApiException).statusCode == 404;

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: const Text('Job Details', style: AppText.screenTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (unavailable)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                child: const Text('This job is no longer accepting applications.', style: TextStyle(color: AppColors.error)),
              ),
            _buildHeader(job),
            const SizedBox(height: 12),
            _buildQuickFacts(job),
            if (job.description.isNotEmpty) _card('About the job', Icons.description_outlined, [
              Text(job.description, style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.primaryText)),
            ]),
            if (job.skills.isNotEmpty)
              _card('Skills required', Icons.lightbulb_outline_rounded, [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.skills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: AppUi.softBlue, borderRadius: BorderRadius.circular(20)),
                            child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
                          ))
                      .toList(),
                ),
              ]),
            if (job.educationRequired.isNotEmpty || job.languages.isNotEmpty)
              _card('Qualifications', Icons.school_outlined, [
                if (job.educationRequired.isNotEmpty) _infoRow('Education', job.educationRequired),
                if (job.languages.isNotEmpty) _infoRow('Languages', job.languages.join(', ')),
              ]),
            if (job.location.full.isNotEmpty)
              _card('Location', Icons.location_on_outlined, [
                Text(job.location.full, style: const TextStyle(fontSize: 14, color: AppColors.primaryText, height: 1.4)),
                if (job.workModel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${job.workModel} role', style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                ],
              ]),
            if (job.companyWebsite.isNotEmpty)
              _card('Company', Icons.business_outlined, [
                InkWell(
                  onTap: () {
                    final uri = Uri.tryParse(job.companyWebsite.startsWith('http') ? job.companyWebsite : 'https://${job.companyWebsite}');
                    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(job.companyWebsite,
                            style: const TextStyle(fontSize: 14, color: AppUi.accent, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.open_in_new_rounded, size: 18, color: AppUi.accent),
                    ],
                  ),
                ),
              ]),
          ],
        ),
        bottomNavigationBar: _buildApplyBar(job, hasApplied, application?.statusLabel, unavailable),
      ),
    );
  }

  Widget _buildHeader(JobModel job) {
    final meta = [
      if (job.postedAgo.isNotEmpty) 'Posted ${job.postedAgo.toLowerCase()}',
      '${job.applicantsCount} ${job.applicantsCount == 1 ? 'applicant' : 'applicants'}',
    ].join('  ·  ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyAvatar(job: job, size: 60),
              const Spacer(),
              JobBadge(job: job),
            ],
          ),
          const SizedBox(height: 14),
          Text(job.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primaryText, height: 1.25)),
          const SizedBox(height: 4),
          Text(job.companyName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
          if (job.location.short.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Expanded(child: Text(job.location.short, style: const TextStyle(fontSize: 13, color: AppColors.secondaryText))),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.borderDark)),
        ],
      ),
    );
  }

  Widget _buildQuickFacts(JobModel job) {
    final facts = <(IconData, String, String)>[
      (Icons.payments_outlined, 'Salary', job.salaryLabel),
      (Icons.trending_up_rounded, 'Experience', job.experienceLabel),
      (Icons.schedule_rounded, 'Job type', job.jobType.isNotEmpty ? job.jobType : '—'),
      (Icons.apartment_rounded, 'Work mode', job.workModel.isNotEmpty ? job.workModel : '—'),
      (Icons.wb_sunny_outlined, 'Shift', job.shiftTiming.isNotEmpty ? job.shiftTiming : '—'),
      (Icons.groups_outlined, 'Openings', '${job.vacancies}'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: facts
          .map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: AppUi.card(radius: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppUi.softBlue, borderRadius: BorderRadius.circular(10)),
                      child: Icon(f.$1, size: 18, color: AppColors.primaryBrand),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$2, style: AppText.label),
                          Text(f.$3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppUi.accent),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.secondaryText))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText))),
        ],
      ),
    );
  }

  Widget _buildApplyBar(JobModel job, bool hasApplied, String? status, bool unavailable) {
    final Widget button;
    if (hasApplied) {
      button = Container(
        height: 52,
        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
            const SizedBox(width: 8),
            Text(status != null && status != 'Applied' ? 'Applied · $status' : 'Applied',
                style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      );
    } else {
      final enabled = !_applying && !unavailable;
      button = GestureDetector(
        onTap: enabled ? () => job.isExternal ? _applyExternal(job) : _applyInApp(job) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: AppUi.heroGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: _applying
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(job.isExternal ? 'Apply on company site' : 'Apply now',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(width: 8),
                      Icon(job.isExternal ? Icons.open_in_new_rounded : Icons.send_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: button,
      ),
    );
  }
}
