import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/jobs_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/job_filter_state.dart';
import '../../../../core/widgets/custom_buttons.dart';

class JobFilterBottomSheet extends ConsumerStatefulWidget {
  final JobFilterState initialFilters;
  final Function(JobFilterState) onApply;

  const JobFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  ConsumerState<JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends ConsumerState<JobFilterBottomSheet> {
  String? _selectedType;
  String? _selectedExperience;
  String? _selectedProfession;
  String? _selectedLocation;
  RangeValues _salaryRange = const RangeValues(0, 5000000);

  final List<String> _types = ['Full-time', 'Part-time', 'Contract', 'Internship', 'Remote'];
  final List<String> _experiences = ['0-1 Years', '1-3 Years', '3-5 Years', '5+ Years'];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialFilters.type;
    _selectedExperience = widget.initialFilters.experience;
    _selectedProfession = widget.initialFilters.profession;
    _selectedLocation = widget.initialFilters.location;
    
    if (widget.initialFilters.salary != null) {
      final parts = widget.initialFilters.salary!.split('-');
      if (parts.length == 2) {
        final min = double.tryParse(parts[0]) ?? 0;
        final max = double.tryParse(parts[1]) ?? 5000000;
        _salaryRange = RangeValues(min, max);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _applyFilters() {
    final newFilters = JobFilterState(
      type: _selectedType,
      experience: _selectedExperience,
      profession: _selectedProfession,
      location: _selectedLocation,
      salary: '${_salaryRange.start.toInt()}-${_salaryRange.end.toInt()}',
    );
    widget.onApply(newFilters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedExperience = null;
      _selectedProfession = null;
      _selectedLocation = null;
      _salaryRange = const RangeValues(0, 5000000);
    });
  }

  @override
  Widget build(BuildContext context) {
    final professionsAsync = ref.watch(jobProfessionsProvider);
    final locationsAsync = ref.watch(jobLocationsProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Jobs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBrand)),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            const Text('Job Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) => _buildChoiceChip(
                label: type, 
                isSelected: _selectedType == type, 
                onSelected: (selected) => setState(() => _selectedType = selected ? type : null),
              )).toList(),
            ),
            const SizedBox(height: 20),

            const Text('Experience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _experiences.map((exp) => _buildChoiceChip(
                label: exp, 
                isSelected: _selectedExperience == exp, 
                onSelected: (selected) => setState(() => _selectedExperience = selected ? exp : null),
              )).toList(),
            ),
            const SizedBox(height: 20),

            const Text('Profession', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: professionsAsync.when(
                  data: (professions) => DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select a profession', style: TextStyle(color: AppColors.secondaryText)),
                    value: professions.contains(_selectedProfession) ? _selectedProfession : null,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryText),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('All Professions')),
                      ...professions.map((prof) => DropdownMenuItem(value: prof, child: Text(prof))),
                    ],
                    onChanged: (value) => setState(() => _selectedProfession = value),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Loading professions...', style: TextStyle(color: AppColors.secondaryText)),
                  ),
                  error: (err, stack) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Error loading professions', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: locationsAsync.when(
                  data: (locations) => DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select a location', style: TextStyle(color: AppColors.secondaryText)),
                    value: locations.contains(_selectedLocation) ? _selectedLocation : null,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryText),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('All Locations')),
                      ...locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))),
                    ],
                    onChanged: (value) => setState(() => _selectedLocation = value),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Loading locations...', style: TextStyle(color: AppColors.secondaryText)),
                  ),
                  error: (err, stack) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Error loading locations', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Salary Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${(_salaryRange.start / 100000).toStringAsFixed(1)}L', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBrand)),
                Text('₹${(_salaryRange.end / 100000).toStringAsFixed(1)}L', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBrand)),
              ],
            ),
            RangeSlider(
              values: _salaryRange,
              min: 0,
              max: 5000000,
              divisions: 50,
              activeColor: AppColors.primaryBrand,
              inactiveColor: AppColors.border,
              labels: RangeLabels(
                '₹${(_salaryRange.start / 100000).toStringAsFixed(1)}L',
                '₹${(_salaryRange.end / 100000).toStringAsFixed(1)}L',
              ),
              onChanged: (values) {
                setState(() {
                  _salaryRange = values;
                });
              },
            ),
            const SizedBox(height: 32),

            PrimaryButton(
              text: 'Apply Filters',
              onPressed: _applyFilters,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool isSelected, required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF054C1E),
      backgroundColor: AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? const Color(0xFF054C1E) : AppColors.secondaryText),
      ),
      showCheckmark: false,
    );
  }
}
