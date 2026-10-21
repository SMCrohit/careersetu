import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../providers/offers_provider.dart';
import '../../domain/offer_model.dart';
import '../../domain/offer_filter_state.dart';
import '../widgets/offer_filter_bottom_sheet.dart';
import 'coupon_details_screen.dart';
import 'claimed_offers_screen.dart';

class OffersHubScreen extends ConsumerStatefulWidget {
  const OffersHubScreen({super.key});

  @override
  ConsumerState<OffersHubScreen> createState() => _OffersHubScreenState();
}

class _OffersHubScreenState extends ConsumerState<OffersHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'All',
    'Gyms & Fitness',
    'Banks & Finance',
    'Coaching & Classes',
    'Books & Stationery',
    'Food & Cafes',
    'Tech & Subscriptions',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(offersProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offerFilters = ref.watch(offerFilterProvider);
    final offersAsyncValue = ref.watch(offersProvider);
    final claimedOffersAsyncValue = ref.watch(claimedOffersListProvider);

    final selectedCategory = offerFilters.category ?? 'All';
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: AppColors.white,
          titleSpacing: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Offers',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Perks & Exclusive Discounts',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const ClaimedOffersScreen())
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryBrand.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wallet, size: 16, color: AppColors.primaryBrand),
                      const SizedBox(width: 4),
                      Text(
                        claimedOffersAsyncValue.maybeWhen(
                          data: (claimed) => 'Rewards (${claimed.length})',
                          orElse: () => 'Rewards',
                        ),
                        style: const TextStyle(
                          color: AppColors.primaryBrand,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.tune, color: AppColors.primaryText, size: 22),
                  if (offerFilters.hasFilters)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBrand,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${offerFilters.activeFiltersCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Filter Offers',
              onPressed: () => _showFilterBottomSheet(context, offerFilters),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(offerCitiesProvider);
              ref.invalidate(offerProfessionsProvider);
              ref.invalidate(offersProvider);
              ref.invalidate(claimedOffersListProvider);
            },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Category Chips Carousel
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            ref.read(offerFilterProvider.notifier).selectCategory(
                              cat == 'All' ? null : cat
                            );
                          },
                          selectedColor: AppColors.primaryBrand,
                          backgroundColor: AppColors.background,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.primaryText,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryBrand : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Active Filters Banner
            if (offerFilters.hasFilters)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 14, color: AppColors.primaryBrand),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            if (offerFilters.city != null) 'City: ${offerFilters.city}',
                            if (offerFilters.category != null) 'Category: ${offerFilters.category}',
                            if (offerFilters.redemptionType != null) 'Type: ${offerFilters.redemptionType}',
                            if (offerFilters.professions.isNotEmpty) 'Professions: ${offerFilters.professions.length}',
                            if (offerFilters.validityUpto != null) 'Valid upto: ${offerFilters.validityUpto}',
                          ].join(' • '),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBrand),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ref.read(offerFilterProvider.notifier).clearAll(),
                        child: const Text('Clear All', style: TextStyle(fontSize: 12, color: AppColors.secondaryText, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ),

            // Offers List
            offersAsyncValue.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBrand.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_offer_outlined, size: 48, color: AppColors.primaryBrand),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'All active offers claimed or none available!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have claimed the available deals, or no offers match this category yet. Check "My Rewards" to view your active passes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                            ),
                            const SizedBox(height: 16),
                            SecondaryButton(
                              text: 'View My Claimed Rewards',
                              width: 220,
                              height: 40,
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => const ClaimedOffersScreen())
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.only(top: 8, bottom: bottomInset + 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == offers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildOfferCard(context, ref, offers[index]);
                      },
                      childCount: offers.length + (ref.watch(offersProvider.notifier).isFetchingMore ? 1 : 0),
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error loading offers: $e'))),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  void _showFilterBottomSheet(BuildContext context, OfferFilterState currentFilters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferFilterBottomSheet(
        initialFilters: currentFilters,
        onApply: (newFilters) {
          ref.read(offerFilterProvider.notifier).updateFilters(newFilters);
        },
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, WidgetRef ref, OfferModel offer) {
    // Category icon helper
    IconData categoryIcon = Icons.local_offer;
    if (offer.type.contains('Gym') || offer.type.contains('Fitness')) {
      categoryIcon = Icons.fitness_center;
    } else if (offer.type.contains('Bank') || offer.type.contains('Loan')) {
      categoryIcon = Icons.account_balance;
    } else if (offer.type.contains('Coaching') || offer.type.contains('Class')) {
      categoryIcon = Icons.school;
    } else if (offer.type.contains('Book') || offer.type.contains('Stationery')) {
      categoryIcon = Icons.menu_book;
    } else if (offer.type.contains('Food') || offer.type.contains('Cafe')) {
      categoryIcon = Icons.restaurant;
    } else if (offer.type.contains('Tech')) {
      categoryIcon = Icons.laptop_mac;
    }

    // Redemption Badge
    String redemptionLabel = 'Universal Code';
    Color badgeBg = AppColors.highlight.withValues(alpha: 0.1);
    Color badgeText = AppColors.highlight;

    if (offer.redemptionType == 'in_store_pass') {
      redemptionLabel = 'In-Store Digital Pass';
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFB45309);
    } else if (offer.redemptionType == 'unique_code_pool') {
      redemptionLabel = 'Exclusive Single-Use Code';
      badgeBg = const Color(0xFFF3E8FF);
      badgeText = const Color(0xFF7E22CE);
    } else if (offer.redemptionType == 'bank_lead') {
      redemptionLabel = 'Instant Callback / Apply';
      badgeBg = const Color(0xFFD1FAE5);
      badgeText = const Color(0xFF047857);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => CouponDetailsScreen(offer: offer))
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Icon + Partner Name + City
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBrand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(categoryIcon, color: AppColors.primaryBrand, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offer.merchantName != null && offer.merchantName!.isNotEmpty)
                            Text(
                              offer.merchantName!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBrand,
                              ),
                            ),
                          Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (offer.city != null && offer.city!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 11, color: AppColors.secondaryText),
                            const SizedBox(width: 2),
                            Text(
                              offer.pincode != null && offer.pincode!.isNotEmpty
                                  ? '${offer.city} (${offer.pincode})'
                                  : offer.city!,
                              style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Subtitle Highlight
                if (offer.subtitle.isNotEmpty)
                  Text(
                    offer.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0284C7),
                    ),
                  ),

                const SizedBox(height: 6),

                // Description
                Text(
                  offer.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Bottom Row: Badges + Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Redemption Type Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        redemptionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
                    ),

                    // Claim / View Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBrand,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => CouponDetailsScreen(offer: offer))
                        );
                      },
                      child: Text(
                        offer.action.isNotEmpty ? offer.action : 'Claim Deal',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
