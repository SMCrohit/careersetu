import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../data/professionals_repository.dart';
import '../../domain/professional_filter_state.dart';
import '../providers/professionals_provider.dart';

/// Advanced filters for professionals, laid out like the Jobs filter sheet.
class ProfessionalFilterSheet extends ConsumerStatefulWidget {
  final ProfessionalFilterState initial;

  /// When the listing is limited to doctors, the profession filter is hidden.
  final bool showProfession;

  const ProfessionalFilterSheet({super.key, required this.initial, this.showProfession = true});

  static Future<ProfessionalFilterState?> show(BuildContext context, ProfessionalFilterState initial, {bool showProfession = true}) {
    return showModalBottomSheet<ProfessionalFilterState>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfessionalFilterSheet(initial: initial, showProfession: showProfession),
    );
  }

  @override
  ConsumerState<ProfessionalFilterSheet> createState() => _ProfessionalFilterSheetState();
}

class _ProfessionalFilterSheetState extends ConsumerState<ProfessionalFilterSheet> {
  late ProfessionalFilterState _f = widget.initial;
  RangeValues? _fee;

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(professionalFilterOptionsProvider).value ?? const ProfessionalFilterOptions();
    final feeMax = (options.feeMax <= 0 ? 5000 : options.feeMax).toDouble();
    _fee ??= RangeValues((_f.minFee ?? 0).toDouble().clamp(0, feeMax), (_f.maxFee ?? feeMax).toDouble().clamp(0, feeMax));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 4),
            child: Row(
              children: [
                const Expanded(child: Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink))),
                TextButton(
                  onPressed: () => setState(() {
                    _f = const ProfessionalFilterState();
                    _fee = RangeValues(0, feeMax);
                  }),
                  child: const Text('Clear all', style: TextStyle(color: AppColors.secondaryText)),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showProfession && options.professions.isNotEmpty)
                    _section('Profession', _chips(options.professions, _f.profession,
                        (v) => _f = v == null ? _f.copyWith(clearProfession: true) : _f.copyWith(profession: v))),
                  if (options.cities.isNotEmpty)
                    _section('City', _chips(options.cities, _f.city, (v) => _f = v == null ? _f.copyWith(clearCity: true) : _f.copyWith(city: v))),
                  _section('Consultation mode', _chips(options.consultationModes, _f.consultationMode,
                      (v) => _f = v == null ? _f.copyWith(clearMode: true) : _f.copyWith(consultationMode: v))),
                  _section(
                    'Consultation fee',
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${_fee!.start.round()}', style: AppText.value),
                            Text(_fee!.end >= feeMax ? '₹${feeMax.round()}+' : '₹${_fee!.end.round()}', style: AppText.value),
                          ],
                        ),
                        RangeSlider(
                          values: _fee!,
                          min: 0,
                          max: feeMax,
                          divisions: (feeMax / 100).clamp(1, 100).round(),
                          activeColor: AppUi.accent,
                          inactiveColor: const Color(0xFFE2E8F0),
                          onChanged: (v) => setState(() => _fee = v),
                        ),
                      ],
                    ),
                  ),
                  _section(
                    'Experience',
                    _chips(ProfessionalFilterState.experienceOptions.values.toList(),
                        ProfessionalFilterState.experienceOptions[_f.experience], (label) {
                      final key = ProfessionalFilterState.experienceOptions.entries.where((e) => e.value == label).map((e) => e.key).firstOrNull;
                      _f = key == null ? _f.copyWith(clearExperience: true) : _f.copyWith(experience: key);
                    }),
                  ),
                  if (options.languages.isNotEmpty)
                    _section('Language', _chips(options.languages, _f.language,
                        (v) => _f = v == null ? _f.copyWith(clearLanguage: true) : _f.copyWith(language: v))),
                  _section('Available on', _chips(ProfessionalFilterState.weekdays, _f.availableDay,
                      (v) => _f = v == null ? _f.copyWith(clearDay: true) : _f.copyWith(availableDay: v))),
                  _section(
                    'Minimum rating',
                    _chips(ProfessionalFilterState.ratingOptions.map((r) => '★ $r+').toList(), _f.minRating == null ? null : '★ ${_f.minRating}+', (label) {
                      final value = label == null ? null : double.tryParse(label.replaceAll(RegExp(r'[^0-9.]'), ''));
                      _f = value == null ? _f.copyWith(clearRating: true) : _f.copyWith(minRating: value);
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: AppUi.card(),
                    child: SwitchListTile(
                      value: _f.featuredOnly,
                      onChanged: (v) => setState(() => _f = _f.copyWith(featuredOnly: v)),
                      activeColor: AppUi.accent,
                      title: const Text('Featured only', style: AppText.value),
                      subtitle: const Text('Handpicked, top-rated professionals', style: AppText.label),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Reset',
                      onPressed: () => Navigator.pop(context, const ProfessionalFilterState()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: 'Apply filters',
                      onPressed: () {
                        final fee = _fee!;
                        Navigator.pop(
                          context,
                          ProfessionalFilterState(
                            profession: _f.profession,
                            city: _f.city,
                            consultationMode: _f.consultationMode,
                            experience: _f.experience,
                            language: _f.language,
                            availableDay: _f.availableDay,
                            minRating: _f.minRating,
                            featuredOnly: _f.featuredOnly,
                            minFee: fee.start > 0 ? fee.start.round() : null,
                            maxFee: fee.end < feeMax ? fee.end.round() : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.value),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// Single-select chips; tapping the selected one clears it.
  Widget _chips(List<String> values, String? selected, void Function(String?) onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => setState(() => onChanged(isSelected ? null : v)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected ? AppUi.accentGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1)),
            ),
            child: Text(v, style: AppText.chip.copyWith(fontSize: 13, color: isSelected ? Colors.white : AppColors.secondaryText)),
          ),
        );
      }).toList(),
    );
  }
}
