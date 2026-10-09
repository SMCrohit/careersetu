import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../../domain/availability.dart';
import '../../domain/professional_model.dart';
import 'professional_avatar.dart';
import 'professional_card.dart';

/// Confirms a booking: summary, consultation mode and notes. Pops with `true` once booked.
class BookingConfirmSheet extends ConsumerStatefulWidget {
  final Professional professional;
  final AvailableDate date;
  final String time;

  const BookingConfirmSheet({super.key, required this.professional, required this.date, required this.time});

  static Future<bool> show(BuildContext context, Professional professional, AvailableDate date, String time) async {
    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingConfirmSheet(professional: professional, date: date, time: time),
    );
    return booked == true;
  }

  @override
  ConsumerState<BookingConfirmSheet> createState() => _BookingConfirmSheetState();
}

class _BookingConfirmSheetState extends ConsumerState<BookingConfirmSheet> {
  final _notes = TextEditingController();
  late String _mode = widget.professional.consultationMode.isNotEmpty ? widget.professional.consultationMode.first : 'In-Person';
  bool _booking = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _booking = true;
      _error = null;
    });
    try {
      await ref.read(appointmentsProvider.notifier).book(
            professionalId: widget.professional.id,
            isoDate: widget.date.isoDate,
            time: widget.time,
            mode: _mode,
            notes: _notes.text,
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not book right now. Please try again.');
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.professional;
    final modes = p.consultationMode.isNotEmpty ? p.consultationMode : const ['In-Person'];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 16),
                const Text('Confirm booking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppUi.card(),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ProfessionalAvatar(professional: p, size: 48, showRing: false),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: AppText.cardTitle),
                                Text(p.subtitle, style: AppText.label),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                      _row(Icons.event_rounded, 'Date', DateFormat('EEEE, d MMMM').format(widget.date.date)),
                      _row(Icons.schedule_rounded, 'Time', widget.time),
                      _row(Icons.payments_outlined, 'Fee', p.feeLabel),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Consultation mode', style: AppText.value),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: modes.map((m) {
                    final selected = m == _mode;
                    return GestureDetector(
                      onTap: () => setState(() => _mode = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: selected ? AppUi.accentGradient : null,
                          color: selected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? Colors.transparent : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(modeIcon(m), size: 16, color: selected ? Colors.white : AppColors.secondaryText),
                          const SizedBox(width: 6),
                          Text(m, style: AppText.chip.copyWith(fontSize: 13, color: selected ? Colors.white : AppColors.secondaryText)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text('Notes (optional)', style: AppText.value),
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppText.body,
                  decoration: InputDecoration(
                    hintText: 'Anything they should know before the session?',
                    hintStyle: AppText.label,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppUi.accent)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!, style: AppText.label.copyWith(color: AppColors.error)),
                  ),
                ],
                const SizedBox(height: 12),
                Text('Your request is sent for confirmation. You\'ll be notified once it\'s confirmed.', style: AppText.label),
                const SizedBox(height: 16),
                PrimaryButton(text: _booking ? 'Booking…' : 'Confirm booking', onPressed: _booking ? null : _confirm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppUi.accent),
          const SizedBox(width: 10),
          Text(label, style: AppText.label),
          const Spacer(),
          Text(value, style: AppText.value.copyWith(fontSize: 13.5)),
        ],
      ),
    );
  }
}
