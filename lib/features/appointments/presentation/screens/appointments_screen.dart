import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../professionals/presentation/screens/professional_details_screen.dart';
import '../../../professionals/presentation/screens/professional_listings_screen.dart';
import '../../../professionals/presentation/widgets/professional_avatar.dart';
import '../../../professionals/presentation/widgets/professional_card.dart';
import '../../../professionals/presentation/widgets/review_sheet.dart';
import '../../domain/appointment_model.dart';
import '../providers/appointments_provider.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  String _tab = 'Upcoming';

  static final _tabs = <String, bool Function(Appointment)>{
    'Upcoming': (a) => a.isUpcoming,
    'Past': (a) => a.isPast,
    'Cancelled': (a) => a.isCancelled,
  };

  void _open(Appointment a) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfessionalDetailsScreen(professional: a.professional, appointment: a)));
  }

  Future<void> _cancel(Appointment a) async {
    final reason = TextEditingController();
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 16),
                const Text('Cancel appointment?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
                const SizedBox(height: 6),
                Text(
                  'With ${a.professional.name}${a.date != null ? ' on ${DateFormat('EEE, d MMM').format(a.date!)} at ${a.time}' : ''}. The slot will be released for others.',
                  style: AppText.subtitle,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reason,
                  decoration: InputDecoration(
                    hintText: 'Reason (optional)',
                    hintStyle: AppText.label,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: SecondaryButton(text: 'Keep it', onPressed: () => Navigator.pop(context, false))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Cancel booking', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(appointmentsProvider.notifier).cancel(a, reason: reason.text);
      if (mounted) CustomToast.showSuccess(context, 'Appointment cancelled');
    } on ApiException catch (e) {
      if (mounted) CustomToast.showError(context, e.message);
    }
  }

  Future<void> _review(Appointment a) async {
    if (await ReviewSheet.show(context, a.professional) && mounted) {
      CustomToast.showSuccess(context, 'Thanks for your review!');
      ref.invalidate(appointmentsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appointmentsProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: const Text('My Appointments', style: AppText.screenTitle),
        ),
        body: RefreshIndicator(
          color: AppUi.accent,
          onRefresh: () => ref.refresh(appointmentsProvider.future),
          child: async.when(
            skipLoadingOnRefresh: true,
            loading: () => ListView(padding: const EdgeInsets.all(16), children: List.generate(3, (_) => const ProfessionalCardSkeleton())),
            error: (e, _) => _message(Icons.cloud_off_rounded, "Couldn't load appointments",
                e is ApiException ? e.message : 'Please check your connection.', 'Try again', () => ref.invalidate(appointmentsProvider)),
            data: (all) {
              if (all.isEmpty) {
                return _message(Icons.event_note_rounded, 'No appointments yet', 'Book a doctor or professional and it will show up here.',
                    'Find a professional', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalListingsScreen())));
              }
              final visible = all.where(_tabs[_tab]!).toList();
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + MediaQuery.of(context).padding.bottom),
                children: [
                  _summary(all),
                  const SizedBox(height: 12),
                  _tabBar(all),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No ${_tab.toLowerCase()} appointments', style: AppText.subtitle)),
                    ),
                  ...visible.map(_card),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summary(List<Appointment> all) {
    final stats = [
      ('Upcoming', all.where((a) => a.isUpcoming).length),
      ('Completed', all.where((a) => a.displayStatus == 'completed').length),
      ('Total', all.length),
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
              child: Column(children: [
                Text('${stats[i].$2}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(stats[i].$1, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ]),
            ),
            if (i < stats.length - 1) Container(width: 1, height: 32, color: Colors.white24),
          ],
        ],
      ),
    );
  }

  Widget _tabBar(List<Appointment> all) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.keys.map((tab) {
          final selected = tab == _tab;
          final count = all.where(_tabs[tab]!).length;
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
              child: Text('$tab ($count)', style: AppText.chip.copyWith(fontSize: 13, color: selected ? Colors.white : AppColors.secondaryText)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _card(Appointment a) {
    final p = a.professional;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppUi.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(a),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfessionalAvatar(professional: p, size: 48, showRing: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.cardTitle),
                          Text(p.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: a.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(a.statusLabel, style: AppText.badge.copyWith(color: a.statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppUi.softBlue, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18, color: AppUi.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.date != null ? '${DateFormat('EEE, d MMM yyyy').format(a.date!)}  ·  ${a.time}' : a.time,
                          style: AppText.value.copyWith(fontSize: 13.5),
                        ),
                      ),
                      ProChip(label: a.consultationMode, icon: a.modeIcon, color: AppColors.secondaryText),
                    ],
                  ),
                ),
                if ((a.notesByStudent ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Note: ${a.notesByStudent}', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.label),
                ],
                if (a.isCancelled && (a.cancellationReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Reason: ${a.cancellationReason}', style: AppText.label),
                ],
                if (a.canCancel || a.canReview || a.isPast || a.isCancelled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (a.canCancel) Expanded(child: SecondaryButton(text: 'Cancel', height: 42, fontSize: 14, onPressed: () => _cancel(a))),
                      if (a.canReview) ...[
                        if (a.canCancel) const SizedBox(width: 10),
                        Expanded(child: PrimaryButton(text: 'Write review', onPressed: () => _review(a))),
                      ],
                      if (!a.canCancel && !a.canReview)
                        Expanded(child: SecondaryButton(text: 'Book again', height: 42, fontSize: 14, onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProfessionalDetailsScreen(professional: p)),
                            ))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle, String action, VoidCallback onAction) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: AppText.screenTitle),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: AppText.subtitle.copyWith(height: 1.4)),
        const SizedBox(height: 20),
        Center(child: PrimaryButton(text: action, width: 230, onPressed: onAction)),
      ],
    );
  }
}
