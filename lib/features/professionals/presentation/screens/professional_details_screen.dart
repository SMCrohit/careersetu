import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../../domain/availability.dart';
import '../../domain/professional_model.dart';
import '../providers/professional_reviews_provider.dart';
import '../providers/professionals_provider.dart';
import '../widgets/booking_confirm_sheet.dart';
import '../widgets/professional_avatar.dart';
import '../widgets/professional_card.dart';
import '../widgets/review_sheet.dart';
import '../widgets/reviews_bottom_sheet.dart';

/// Profile of a professional with booking. When opened from My Appointments, [appointment]
/// replaces the booking bar with that appointment's status and actions.
class ProfessionalDetailsScreen extends ConsumerStatefulWidget {
  final Professional professional;
  final Appointment? appointment;

  const ProfessionalDetailsScreen({super.key, required this.professional, this.appointment});

  @override
  ConsumerState<ProfessionalDetailsScreen> createState() => _ProfessionalDetailsScreenState();
}

class _ProfessionalDetailsScreenState extends ConsumerState<ProfessionalDetailsScreen> {
  String? _selectedDate;
  String? _selectedTime;

  Professional get _initial => widget.professional;

  Future<void> _book(Professional p, List<AvailableDate> dates) async {
    final date = dates.where((d) => d.isoDate == _selectedDate).firstOrNull;
    final time = _selectedTime;
    if (date == null || time == null) return;
    final booked = await BookingConfirmSheet.show(context, p, date, time);
    if (!mounted) return;
    setState(() => _selectedTime = null);
    if (booked) {
      CustomToast.showSuccess(context, 'Booking requested for ${DateFormat('EEE, d MMM').format(date.date)} at $time');
    }
    // Refresh in both cases: a failed booking usually means the slot just filled.
    ref.invalidate(professionalAvailabilityProvider(p.id));
  }

  Future<void> _cancelAppointment(Appointment a) async {
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
                const Text('Cancel appointment?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
                const SizedBox(height: 6),
                const Text('The slot will be released for others.', style: AppText.subtitle),
                const SizedBox(height: 14),
                TextField(
                  controller: reason,
                  decoration: InputDecoration(
                    hintText: 'Reason (optional)',
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
      if (mounted) {
        CustomToast.showSuccess(context, 'Appointment cancelled');
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) CustomToast.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(professionalDetailsProvider(_initial.id)).value ?? _initial;
    final availability = ref.watch(professionalAvailabilityProvider(p.id));
    final dates = availability.value ?? const <AvailableDate>[];
    // Default to the first open date once availability loads.
    if (_selectedDate == null && dates.isNotEmpty) _selectedDate = dates.first.isoDate;
    final selectedDate = dates.where((d) => d.isoDate == _selectedDate).firstOrNull;

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: Text(p.isDoctor ? 'Doctor profile' : 'Profile', style: AppText.screenTitle),
        ),
        body: RefreshIndicator(
          color: AppUi.accent,
          onRefresh: () async {
            ref.invalidate(professionalDetailsProvider(p.id));
            ref.invalidate(professionalReviewsProvider(p.id));
            ref.invalidate(professionalAvailabilityProvider(p.id));
            await ref.read(professionalAvailabilityProvider(p.id).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _header(p),
              const SizedBox(height: 12),
              _quickFacts(p),
              if ((p.description ?? '').isNotEmpty) _card('About', Icons.info_outline_rounded, [Text(p.description!, style: AppText.body)]),
              _card(p.isDoctor ? 'Clinic' : 'Office', Icons.apartment_rounded, [
                Text(p.clinic.isNotEmpty ? p.clinic : '—', style: AppText.value),
                if (p.locationCity.isNotEmpty) Text(p.locationCity, style: AppText.label),
              ]),
              if (p.languagesSpoken.isNotEmpty || p.consultationMode.isNotEmpty)
                _card('Consultation', Icons.forum_outlined, [
                  if (p.consultationMode.isNotEmpty) ...[
                    const Text('Modes', style: AppText.label),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: p.consultationMode.map((m) => ProChip(label: m, icon: modeIcon(m))).toList()),
                    const SizedBox(height: 10),
                  ],
                  if (p.languagesSpoken.isNotEmpty) ...[
                    const Text('Languages', style: AppText.label),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: p.languagesSpoken.map((l) => ProChip(label: l, color: AppColors.secondaryText)).toList()),
                  ],
                ]),
              if (widget.appointment == null) _bookingCard(p, availability, dates, selectedDate),
              _reviewsPreview(p),
            ],
          ),
        ),
        bottomNavigationBar: _bottomBar(p, dates),
      ),
    );
  }

  Widget _header(Professional p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(radius: 20),
      child: Row(
        children: [
          ProfessionalAvatar(professional: p, size: 76),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.isFeatured) ...[const ProChip(label: 'Featured', icon: Icons.star_rounded, color: Color(0xFF0284C7)), const SizedBox(height: 6)],
                Text(p.name, style: AppText.cardTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(p.subtitle, style: AppText.subtitle.copyWith(fontSize: 13.5)),
                if (p.qualification != null) Text(p.qualification!, style: AppText.label),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickFacts(Professional p) {
    final facts = <(IconData, String, String, VoidCallback?)>[
      (Icons.workspace_premium_outlined, 'Experience', p.experienceLabel, null),
      (Icons.star_rounded, 'Rating', '${p.ratingLabel}${p.reviews > 0 ? ' (${p.reviews})' : ''}', () => ReviewsBottomSheet.show(context, p)),
      (Icons.payments_outlined, 'Fee', p.feeLabel, null),
      (Icons.event_available_outlined, 'Available', p.daysLabel.isNotEmpty ? p.daysLabel : '—', null),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: facts.map((f) {
        return GestureDetector(
          onTap: f.$4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: AppUi.card(radius: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppUi.iconTile, borderRadius: BorderRadius.circular(10)),
                  child: Icon(f.$1, size: 18, color: AppUi.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$2, style: AppText.label),
                      Text(f.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.value.copyWith(fontSize: 13.5)),
                    ],
                  ),
                ),
                if (f.$4 != null) const Icon(Icons.chevron_right, size: 18, color: AppColors.borderDark),
              ],
            ),
          ),
        );
      }).toList(),
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
          Row(children: [
            Icon(icon, size: 20, color: AppUi.accent),
            const SizedBox(width: 8),
            Text(title, style: AppText.sectionTitle),
          ]),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _bookingCard(Professional p, AsyncValue<List<AvailableDate>> availability, List<AvailableDate> dates, AvailableDate? selected) {
    Widget body;
    if (availability.isLoading && dates.isEmpty) {
      body = const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: AppUi.accent)));
    } else if (availability.hasError && dates.isEmpty) {
      body = Column(children: [
        Text(availability.error is ApiException ? (availability.error as ApiException).message : 'Could not load slots.', style: AppText.subtitle),
        TextButton(onPressed: () => ref.invalidate(professionalAvailabilityProvider(p.id)), child: const Text('Try again')),
      ]);
    } else if (dates.isEmpty) {
      body = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
        child: const Text('No open slots in the next 30 days. Please check back later.', style: AppText.subtitle),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = dates[i];
                final isSelected = d.isoDate == selected?.isoDate;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = d.isoDate;
                    _selectedTime = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 62,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppUi.accentGradient : null,
                      color: isSelected ? null : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(d.weekday, style: AppText.label.copyWith(color: isSelected ? Colors.white70 : AppColors.secondaryText)),
                        Text('${d.date.day}', style: AppText.cardTitle.copyWith(fontSize: 18, color: isSelected ? Colors.white : AppColors.primaryText)),
                        Text(DateFormat('MMM').format(d.date), style: AppText.label.copyWith(fontSize: 11, color: isSelected ? Colors.white70 : AppColors.secondaryText)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: 14),
            Text(
              '${selected.openCount} open ${selected.openCount == 1 ? 'slot' : 'slots'}'
              '${selected.mineCount > 0 ? ' · ${selected.mineCount} booked by you' : ''}'
              ' on ${DateFormat('EEEE, d MMM').format(selected.date)}',
              style: AppText.label,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.slots.map((s) {
                final isSelected = s.time == _selectedTime;
                final enabled = s.isAvailable;
                const mineColor = Color(0xFF059669);
                return GestureDetector(
                  onTap: enabled ? () => setState(() => _selectedTime = s.time) : null,
                  child: Container(
                    width: 96,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppUi.accentGradient : null,
                      color: isSelected ? null : (s.isMine ? const Color(0xFFECFDF5) : (enabled ? Colors.white : const Color(0xFFF1F5F9))),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (s.isMine ? const Color(0xFFA7F3D0) : (enabled ? const Color(0xFFBAE6FD) : Colors.transparent)),
                      ),
                    ),
                    child: Column(children: [
                      Text(s.time.replaceFirst(RegExp(r'^0'), ''),
                          style: AppText.value.copyWith(
                            fontSize: 13,
                            color: isSelected ? Colors.white : (s.isMine ? mineColor : (enabled ? AppColors.primaryText : AppColors.borderDark)),
                            decoration: s.status == 'past' ? TextDecoration.lineThrough : null,
                          )),
                      if (s.status == 'full') Text('Full', style: AppText.badge.copyWith(fontSize: 10, color: AppColors.error)),
                      if (s.isMine) Text('Booked', style: AppText.badge.copyWith(fontSize: 10, color: mineColor)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      );
    }

    return _card('Book an appointment', Icons.event_rounded, [body]);
  }

  Widget _reviewsPreview(Professional p) {
    final reviews = ref.watch(professionalReviewsProvider(p.id));
    final list = reviews.value ?? const [];
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.reviews_outlined, size: 20, color: AppUi.accent),
            const SizedBox(width: 8),
            const Expanded(child: Text('Reviews', style: AppText.sectionTitle)),
            if (list.isNotEmpty) TextButton(onPressed: () => ReviewsBottomSheet.show(context, p), child: Text('See all (${list.length})')),
          ]),
          const SizedBox(height: 6),
          if (reviews.isLoading && list.isEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(color: AppUi.accent, strokeWidth: 2)))
          else if (list.isEmpty)
            const Text('No reviews yet.', style: AppText.subtitle)
          else
            ...list.take(2).map((r) => ReviewTile(review: r)),
        ],
      ),
    );
  }

  Widget _bottomBar(Professional p, List<AvailableDate> dates) {
    final a = widget.appointment;
    Widget content;
    if (a != null) {
      content = Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.statusLabel, style: AppText.value.copyWith(color: a.statusColor)),
                if (a.date != null) Text('${DateFormat('EEE, d MMM').format(a.date!)} · ${a.time}', style: AppText.label),
              ],
            ),
          ),
          if (a.canCancel) SizedBox(width: 150, child: SecondaryButton(text: 'Cancel', onPressed: () => _cancelAppointment(a))),
          if (a.canReview)
            SizedBox(
              width: 160,
              child: PrimaryButton(
                text: 'Write review',
                onPressed: () async {
                  if (await ReviewSheet.show(context, p) && mounted) {
                    CustomToast.showSuccess(context, 'Thanks for your review!');
                    ref.invalidate(appointmentsProvider);
                  }
                },
              ),
            ),
        ],
      );
    } else {
      content = Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Consultation fee', style: AppText.label),
              Text(p.feeLabel, style: AppText.cardTitle.copyWith(fontSize: 20)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PrimaryButton(
              text: _selectedTime == null ? 'Select a slot' : 'Book $_selectedTime',
              onPressed: _selectedTime == null ? null : () => _book(p, dates),
            ),
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: content,
      ),
    );
  }
}
