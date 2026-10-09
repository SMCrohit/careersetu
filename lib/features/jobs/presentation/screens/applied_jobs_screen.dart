import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../home/presentation/providers/navigation_provider.dart';
import '../../domain/job_application.dart';
import '../providers/jobs_provider.dart';
import '../widgets/applied_job_card.dart';
import '../widgets/job_card.dart';
import 'job_details_screen.dart';

class AppliedJobsScreen extends ConsumerStatefulWidget {
  const AppliedJobsScreen({super.key});

  @override
  ConsumerState<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
}

class _AppliedJobsScreenState extends ConsumerState<AppliedJobsScreen> {
  String _tab = 'All';

  static final _tabs = <String, bool Function(JobApplication)>{
    'All': (_) => true,
    'Active': (a) => !a.isClosed,
    'Interview': (a) => a.isInterview,
    'Closed': (a) => a.isClosed,
  };

  void _browseJobs() {
    // Jobs is the second tab in the bottom navigation.
    ref.read(navigationIndexProvider.notifier).setIndex(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(appliedJobsProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: const Text('Applied Jobs', style: AppText.screenTitle),
        ),
        body: RefreshIndicator(
          color: AppUi.accent,
          onRefresh: () => ref.refresh(appliedJobsProvider.future),
          child: applicationsAsync.when(
            skipLoadingOnRefresh: true,
            loading: () => ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(3, (_) => const JobCardSkeleton()),
            ),
            error: (e, _) => _message(
              Icons.cloud_off_rounded,
              "Couldn't load your applications",
              e is ApiException ? e.message : 'Please check your connection and try again.',
              ('Try again', () => ref.invalidate(appliedJobsProvider)),
            ),
            data: (applications) {
              if (applications.isEmpty) {
                return _message(
                  Icons.work_outline_rounded,
                  'No applications yet',
                  'Jobs you apply to will show up here, along with their status.',
                  ('Browse jobs', _browseJobs),
                );
              }
              final visible = applications.where(_tabs[_tab]!).toList();
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + MediaQuery.of(context).padding.bottom),
                children: [
                  _summary(applications),
                  const SizedBox(height: 12),
                  _tabBar(applications),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No ${_tab.toLowerCase()} applications',
                            style: const TextStyle(color: AppColors.secondaryText)),
                      ),
                    ),
                  ...visible.map((a) => AppliedJobCard(
                        application: a,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(job: a.job))),
                      )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summary(List<JobApplication> apps) {
    final stats = [
      ('Applied', apps.length),
      ('Active', apps.where((a) => !a.isClosed).length),
      ('Interviews', apps.where((a) => a.isInterview).length),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: AppUi.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Text('${stats[i].$2}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(stats[i].$1, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            if (i < stats.length - 1) Container(width: 1, height: 32, color: Colors.white24),
          ],
        ],
      ),
    );
  }

  Widget _tabBar(List<JobApplication> apps) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.keys.map((tab) {
          final selected = tab == _tab;
          final count = apps.where(_tabs[tab]!).length;
          return GestureDetector(
            onTap: () => setState(() => _tab = tab),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? AppUi.accentGradient : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE2E8F0)),
              ),
              child: Text('$tab ($count)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.secondaryText,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle, (String, VoidCallback) action) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.secondaryText, height: 1.4)),
        const SizedBox(height: 18),
        Center(
          child: GestureDetector(
            onTap: action.$2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(gradient: AppUi.heroGradient, borderRadius: BorderRadius.circular(24)),
              child: Text(action.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}
