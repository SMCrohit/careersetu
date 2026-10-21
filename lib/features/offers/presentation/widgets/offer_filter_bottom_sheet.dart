import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../domain/offer_filter_state.dart';
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
  String? _selectedRedemptionType;
  late List<String> _selectedProfessions;
  String? _selectedValidityUpto;
  String _professionSearch = '';

  static const List<String> _categories = [
    'Gyms & Fitness',
    'Banks & Finance',
    'Coaching & Classes',
    'Books & Stationery',
    'Food & Cafes',
    'Tech & Subscriptions',
  ];

  static const List<Map<String, String>> _redemptionTypes = [
    {'value': 'in_store_pass', 'label': 'In-Store Pass'},
    {'value': 'generic_code', 'label': 'Universal Coupon'},
    {'value': 'unique_code_pool', 'label': 'Unique Voucher Pool'},
    {'value': 'bank_lead', 'label': 'Bank Assistance Lead'},
    {'value': 'affiliate_link', 'label': 'Direct Link'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialFilters.city;
    _selectedCategory = widget.initialFilters.category;
    _selectedRedemptionType = widget.initialFilters.redemptionType;
    _selectedProfessions = List<String>.from(widget.initialFilters.professions);
    _selectedValidityUpto = widget.initialFilters.validityUpto;
  }

  void _applyFilters() {
    final newFilters = OfferFilterState(
      city: _selectedCity,
      category: _selectedCategory,
      redemptionType: _selectedRedemptionType,
      professions: _selectedProfessions,
      validityUpto: _selectedValidityUpto,
    );
    widget.onApply(newFilters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategory = null;
      _selectedRedemptionType = null;
      _selectedProfessions = [];
      _selectedValidityUpto = null;
      _professionSearch = '';
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_selectedValidityUpto != null) {
      final parsed = DateTime.tryParse(_selectedValidityUpto!);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBrand,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _selectedValidityUpto = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsyncValue = ref.watch(offerCitiesProvider);
    final professionsAsyncValue = ref.watch(offerProfessionsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primaryBrand, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Filter Offers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Scrollable filter options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. City (Location) Dropdown
                  const Text(
                    'City (Location)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 8),
                  citiesAsyncValue.when(
                    data: (cities) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('All Cities', style: TextStyle(fontSize: 14)),
                            value: _selectedCity,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Cities', style: TextStyle(fontSize: 14)),
                              ),
                              ...cities.map((city) {
                                return DropdownMenuItem<String>(
                                  value: city,
                                  child: Text(city, style: const TextStyle(fontSize: 14)),
                                );
                              }),
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
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (err, _) => Text(
                      'Failed to load cities',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Select Category
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? cat : null;
                          });
                        },
                        selectedColor: AppColors.primaryBrand.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryBrand : AppColors.primaryText,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: AppColors.background,
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryBrand : AppColors.border,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 3. Select Redemption Type
                  const Text(
                    'Redemption Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('All Redemption Types', style: TextStyle(fontSize: 14)),
                        value: _selectedRedemptionType,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Redemption Types', style: TextStyle(fontSize: 14)),
                          ),
                          ..._redemptionTypes.map((rt) {
                            return DropdownMenuItem<String>(
                              value: rt['value'],
                              child: Text(rt['label']!, style: const TextStyle(fontSize: 14)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedRedemptionType = val;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Select Profession (Multi-select)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Profession ${_selectedProfessions.isNotEmpty ? '(${_selectedProfessions.length})' : ''}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                      ),
                      if (_selectedProfessions.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _selectedProfessions.clear()),
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryBrand, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  professionsAsyncValue.when(
                    data: (allProfessions) {
                      final filtered = allProfessions.where((p) {
                        if (_professionSearch.isEmpty) return true;
                        return p.toLowerCase().contains(_professionSearch.toLowerCase());
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (allProfessions.length > 8)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search professions...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.secondaryText),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (val) => setState(() => _professionSearch = val),
                              ),
                            ),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 160),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: filtered.map((prof) {
                                  final isSelected = _selectedProfessions.contains(prof);
                                  return FilterChip(
                                    label: Text(prof, style: const TextStyle(fontSize: 11)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedProfessions.add(prof);
                                        } else {
                                          _selectedProfessions.remove(prof);
                                        }
                                      });
                                    },
                                    selectedColor: AppColors.primaryBrand.withValues(alpha: 0.12),
                                    labelStyle: TextStyle(
                                      color: isSelected ? AppColors.primaryBrand : AppColors.primaryText,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: isSelected ? AppColors.primaryBrand : AppColors.border,
                                    ),
                                    showCheckmark: isSelected,
                                    checkmarkColor: AppColors.primaryBrand,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (err, _) => Text(
                      'Failed to load professions',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Validity Upto Date
                  const Text(
                    'Validity Upto Date',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.secondaryText),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedValidityUpto ?? 'Select cutoff date (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedValidityUpto != null
                                    ? AppColors.primaryText
                                    : AppColors.secondaryText,
                                fontWeight: _selectedValidityUpto != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_selectedValidityUpto != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedValidityUpto = null),
                              child: const Icon(Icons.close, size: 18, color: AppColors.secondaryText),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 12,
            ),
            child: PrimaryButton(
              text: 'Apply Filters',
              onPressed: _applyFilters,
            ),
          ),
        ],
      ),
    );
  }
}
