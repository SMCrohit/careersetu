import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/job_filter_state.dart';
import '../../../../core/widgets/custom_buttons.dart';

class JobFilterBottomSheet extends StatefulWidget {
  final JobFilterState initialFilters;
  final Function(JobFilterState) onApply;

  const JobFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends State<JobFilterBottomSheet> {
  String? _selectedType;
  String? _selectedExperience;
  String? _selectedProfession;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  final List<String> _types = ['Full-time', 'Part-time', 'Contract', 'Internship', 'Remote'];
  final List<String> _experiences = ['0-1 Years', '1-3 Years', '3-5 Years', '5+ Years'];
  final List<String> _professions = [
    'Professional', 'Engineer', 'IAS', 'IPS', 'Teacher', 
    'Lawyer', 'Nurse', 'Software Developer', 'Accountant', 'Banker', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialFilters.type;
    _selectedExperience = widget.initialFilters.experience;
    _selectedProfession = widget.initialFilters.profession;
    _locationController.text = widget.initialFilters.location ?? '';
    _salaryController.text = widget.initialFilters.salary ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final newFilters = JobFilterState(
      type: _selectedType,
      experience: _selectedExperience,
      profession: _selectedProfession,
      location: _locationController.text.isNotEmpty ? _locationController.text : null,
      salary: _salaryController.text.isNotEmpty ? _salaryController.text : null,
    );
    widget.onApply(newFilters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedExperience = null;
      _selectedProfession = null;
      _locationController.clear();
      _salaryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select a profession', style: TextStyle(color: AppColors.secondaryText)),
                  value: _selectedProfession,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryText),
                  items: _professions.map((prof) => DropdownMenuItem(value: prof, child: Text(prof))).toList(),
                  onChanged: (value) => setState(() => _selectedProfession = value),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. Bengaluru, Remote',
                hintStyle: const TextStyle(color: AppColors.secondaryText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Salary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            TextField(
              controller: _salaryController,
              decoration: InputDecoration(
                hintText: 'e.g. 50k, 10 LPA',
                hintStyle: const TextStyle(color: AppColors.secondaryText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
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
