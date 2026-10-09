import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/jobs_repository.dart';
import '../../domain/job_filter_state.dart';
import '../providers/jobs_provider.dart';

/// Advanced job filters, laid out like the admin "Advanced Filters" drawer.
class JobFilterBottomSheet extends ConsumerStatefulWidget {
  final JobFilterState initialFilters;
  final ValueChanged<JobFilterState> onApply;

  const JobFilterBottomSheet({super.key, required this.initialFilters, required this.onApply});

  @override
  ConsumerState<JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends ConsumerState<JobFilterBottomSheet> {
  late JobFilterState _f;
  late RangeValues _salary;

  static const _defaultTypes = ['Full-time', 'Part-time', 'Contract', 'Internship'];
  static const _defaultWorkModels = ['On-Site', 'Remote', 'Hybrid'];
  static const _cap = JobFilterState.salaryCap;

  @override
  void initState() {
    super.initState();
    _f = widget.initialFilters;
    _salary = RangeValues((_f.minSalary ?? 0).toDouble(), (_f.maxSalary ?? _cap).toDouble().clamp(0, _cap.toDouble()));
  }

  String _lakh(double v) => v >= _cap ? '₹50L+' : (v == 0 ? '₹0' : '₹${(v / 100000).toStringAsFixed(v % 100000 == 0 ? 0 : 1)}L');

  void _apply() {
    widget.onApply(JobFilterState(
      type: _f.type,
      workModel: _f.workModel,
      city: _f.city,
      experience: _f.experience,
      postedWithinDays: _f.postedWithinDays,
      minSalary: _salary.start > 0 ? _salary.start.round() : null,
      maxSalary: _salary.end < _cap ? _salary.end.round() : null,
    ));
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _f = const JobFilterState();
      _salary = const RangeValues(0, _cap * 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(jobFilterOptionsProvider).value ?? const JobFilterOptions();
    final types = {..._defaultTypes, ...options.jobTypes}.toList();
    final workModels = {..._defaultWorkModels, ...options.workModels}.toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppUi.accent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Advanced Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                ),
                TextButton(onPressed: _clear, child: const Text('Clear all', style: TextStyle(color: AppColors.secondaryText))),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Job Type', _chips(types, _f.type, (v) => setState(() => _f = v == null ? _f.copyWith(clearType: true) : _f.copyWith(type: v)))),
                  _section('Work Mode',
                      _chips(workModels, _f.workModel, (v) => setState(() => _f = v == null ? _f.copyWith(clearWorkModel: true) : _f.copyWith(workModel: v)))),
                  _section('City (Location)', _cityPicker(options.cities)),
                  _section(
                    'Experience Level',
                    _chips(JobFilterState.experienceOptions, _f.experience,
                        (v) => setState(() => _f = v == null ? _f.copyWith(clearExperience: true) : _f.copyWith(experience: v))),
                  ),
                  _section(
                    'Salary (per year)',
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _valueBox('Min', _lakh(_salary.start)),
                            const Text('–', style: TextStyle(color: AppColors.secondaryText)),
                            _valueBox('Max', _lakh(_salary.end)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppUi.accent,
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            thumbColor: Colors.white,
                            overlayColor: AppUi.accent.withOpacity(0.12),
                            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
                          ),
                          child: RangeSlider(
                            values: _salary,
                            min: 0,
                            max: _cap.toDouble(),
                            divisions: 50,
                            onChanged: (v) => setState(() => _salary = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _section(
                    'Date Posted',
                    _chips(JobFilterState.postedOptions.values.toList(),
                        JobFilterState.postedOptions[_f.postedWithinDays], (label) {
                      final days = JobFilterState.postedOptions.entries.where((e) => e.value == label).map((e) => e.key).firstOrNull;
                      setState(() => _f = days == null ? _f.copyWith(clearPosted: true) : _f.copyWith(postedWithinDays: days));
                    }),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clear();
                        _apply();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.primaryText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _apply,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(gradient: AppUi.heroGradient, borderRadius: BorderRadius.circular(14)),
                        alignment: Alignment.center,
                        child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
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
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// Single-select chips; tapping the selected chip clears it.
  Widget _chips(List<String> values, String? selected, ValueChanged<String?> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onChanged(isSelected ? null : v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected ? AppUi.accentGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1)),
            ),
            child: Text(v,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.secondaryText,
                )),
          ),
        );
      }).toList(),
    );
  }

  Widget _cityPicker(List<String> cities) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _CitySearchSheet(cities: cities, selected: _f.city),
        );
        if (picked == null) return;
        setState(() => _f = picked.isEmpty ? _f.copyWith(clearCity: true) : _f.copyWith(city: picked));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20, color: AppUi.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_f.city ?? 'All locations',
                  style: TextStyle(fontSize: 14, color: _f.city != null ? AppColors.primaryText : AppColors.secondaryText)),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _valueBox(String label, String value) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppUi.softBlue, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
        ],
      ),
    );
  }
}

/// Searchable list of cities. Pops with the city, or '' for "All locations".
class _CitySearchSheet extends StatefulWidget {
  final List<String> cities;
  final String? selected;

  const _CitySearchSheet({required this.cities, this.selected});

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.cities.where((c) => c.toLowerCase().contains(_query.toLowerCase())).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search city',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_query.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.public),
                      title: const Text('All locations'),
                      trailing: widget.selected == null ? const Icon(Icons.check, color: AppUi.accent) : null,
                      onTap: () => Navigator.pop(context, ''),
                    ),
                  ...matches.map((c) => ListTile(
                        leading: const Icon(Icons.location_city_outlined),
                        title: Text(c),
                        trailing: c == widget.selected ? const Icon(Icons.check, color: AppUi.accent) : null,
                        onTap: () => Navigator.pop(context, c),
                      )),
                  if (matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No jobs in that city yet', style: TextStyle(color: AppColors.secondaryText))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
