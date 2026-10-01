import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/offer_filter_state.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../providers/offers_provider.dart';

class OfferFilterBottomSheet extends ConsumerStatefulWidget {
  final OfferFilterState initialFilters;
  final Function(OfferFilterState) onApply;

  const OfferFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  ConsumerState<OfferFilterBottomSheet> createState() => _OfferFilterBottomSheetState();
}

class _OfferFilterBottomSheetState extends ConsumerState<OfferFilterBottomSheet> {
  String? _selectedCity;
  String? _selectedCategory;

  final List<String> _categories = ['Education', 'Loans', 'Services', 'Health'];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialFilters.city;
    _selectedCategory = widget.initialFilters.category;
  }

  void _applyFilters() {
    final newFilters = OfferFilterState(
      city: _selectedCity,
      category: _selectedCategory,
    );
    widget.onApply(newFilters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsyncValue = ref.watch(offerCitiesProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
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
                const Text('Filter Offers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBrand)),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All', style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
                )
              ],
            ),
            const SizedBox(height: 24),
            
            const Text('City', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
            const SizedBox(height: 12),
            citiesAsyncValue.when(
              data: (cities) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('All Cities'),
                      value: _selectedCity,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Cities'),
                        ),
                        ...cities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        })
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCity = val;
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text('Error loading cities: $err'),
            ),
            
            const SizedBox(height: 24),
            
            const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  selectedColor: AppColors.primaryBrand.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryBrand : AppColors.secondaryText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.background,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Apply Filters',
              onPressed: _applyFilters,
            ),
          ],
        ),
      ),
    );
  }
}
