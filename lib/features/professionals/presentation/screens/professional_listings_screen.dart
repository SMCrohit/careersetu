import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../data/professionals_repository.dart';
import '../../domain/professional_filter_state.dart';
import '../../domain/professional_model.dart';
import '../providers/professionals_provider.dart';
import '../widgets/professional_card.dart';
import '../widgets/professional_filter_sheet.dart';
import 'professional_details_screen.dart';

/// Directory of professionals, optionally limited to doctors or non-doctors.
class ProfessionalListingsScreen extends ConsumerStatefulWidget {
  final ProfessionalGroup? group;

  const ProfessionalListingsScreen({super.key, this.group});

  @override
  ConsumerState<ProfessionalListingsScreen> createState() => _ProfessionalListingsScreenState();
}

class _ProfessionalListingsScreenState extends ConsumerState<ProfessionalListingsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// False until the group, search and filters are reset for this visit.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Start fresh each time the directory opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listingGroupProvider.notifier).set(widget.group);
      ref.read(professionalSearchQueryProvider.notifier).updateQuery('');
      ref.read(professionalFiltersProvider.notifier).clear();
      if (mounted) setState(() => _ready = true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        ref.read(professionalsListProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => ref.read(professionalSearchQueryProvider.notifier).updateQuery(value));
  }

  Future<void> _openFilters(ProfessionalFilterState current) async {
    final result = await ProfessionalFilterSheet.show(context, current, showProfession: widget.group != ProfessionalGroup.doctor);
    if (result != null) ref.read(professionalFiltersProvider.notifier).update(result);
  }

  void _clearAll() {
    _searchController.clear();
    ref.read(professionalSearchQueryProvider.notifier).updateQuery('');
    ref.read(professionalFiltersProvider.notifier).clear();
  }

  String get _title => switch (widget.group) {
        ProfessionalGroup.doctor => 'Doctors',
        ProfessionalGroup.nonDoctor => 'Professionals',
        null => 'Find a professional',
      };

  @override
  Widget build(BuildContext context) {
    final listAsync = _ready ? ref.watch(professionalsListProvider) : const AsyncLoading<List<Professional>>();
    final notifier = ref.read(professionalsListProvider.notifier);
    final filters = ref.watch(professionalFiltersProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient),
      padding: EdgeInsets.only(bottom: 24),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: AppText.screenTitle),
              Text(listAsync.hasValue ? '${notifier.total} available' : 'Loading…', style: AppText.label),
            ],
          ),
        ),
        body: Column(
          children: [
            _searchRow(filters),
            if (filters.activeCount > 0) _activeFilters(filters),
            Expanded(
              child: RefreshIndicator(
                color: AppUi.accent,
                onRefresh: () => ref.refresh(professionalsListProvider.future),
                child: listAsync.when(
                  skipLoadingOnRefresh: true,
                  loading: () => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: List.generate(4, (_) => const ProfessionalCardSkeleton()),
                  ),
                  error: (e, _) => _message(Icons.cloud_off_rounded, "Couldn't load professionals",
                      e is ApiException ? e.message : 'Please check your connection.', 'Try again', () => ref.invalidate(professionalsListProvider)),
                  data: (items) => items.isEmpty
                      ? _message(
                          Icons.person_search_rounded,
                          'No one matches',
                          'Try removing some filters or searching for something else.',
                          'Clear search & filters',
                          _clearAll,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: items.length + (notifier.hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(color: AppUi.accent, strokeWidth: 2.5)),
                              );
                            }
                            final p = items[i];
                            return ProfessionalCard(
                              professional: p,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfessionalDetailsScreen(professional: p))),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchRow(ProfessionalFilterState filters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: AppUi.card(radius: 14),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                style: AppText.body,
                decoration: InputDecoration(
                  hintText: 'Search name, specialty, clinic…',
                  hintStyle: AppText.label.copyWith(fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppUi.accent),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.secondaryText),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _openFilters(filters),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppUi.heroGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
                if (filters.activeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: const Color(0xFFF97316), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Text('${filters.activeCount}', style: AppText.badge.copyWith(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeFilters(ProfessionalFilterState f) {
    final n = ref.read(professionalFiltersProvider.notifier);
    final chips = <(String, ProfessionalFilterState)>[
      if (f.profession != null) (f.profession!, f.copyWith(clearProfession: true)),
      if (f.city != null) (f.city!, f.copyWith(clearCity: true)),
      if (f.consultationMode != null) (f.consultationMode!, f.copyWith(clearMode: true)),
      if (f.hasFee) ('₹${f.minFee ?? 0} – ${f.maxFee != null ? '₹${f.maxFee}' : 'any'}', f.copyWith(clearFee: true)),
      if (f.experience != null) (ProfessionalFilterState.experienceOptions[f.experience] ?? f.experience!, f.copyWith(clearExperience: true)),
      if (f.language != null) (f.language!, f.copyWith(clearLanguage: true)),
      if (f.availableDay != null) ('Available ${f.availableDay}', f.copyWith(clearDay: true)),
      if (f.minRating != null) ('★ ${f.minRating}+', f.copyWith(clearRating: true)),
      if (f.featuredOnly) ('Featured', f.copyWith(featuredOnly: false)),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final (label, without) in chips)
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 6),
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppUi.accent.withOpacity(0.5)),
              ),
              child: Row(children: [
                Text(label, style: AppText.chip.copyWith(fontSize: 12.5)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  onPressed: () => n.update(without),
                  icon: const Icon(Icons.close_rounded, color: AppColors.primaryBrand),
                ),
              ]),
            ),
          TextButton(onPressed: n.clear, child: const Text('Clear all')),
        ],
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle, String action, VoidCallback onAction) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 70, 32, 24),
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
        Center(child: SecondaryButton(text: action, width: 230, onPressed: onAction)),
      ],
    );
  }
}
