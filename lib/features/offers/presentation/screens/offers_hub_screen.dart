import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scratcher/scratcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.white,
        title: const Text('Local Offers', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ClaimedOffersScreen()));
            },
            child: const Text('Claimed', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primaryText),
            onPressed: () => _showFilterBottomSheet(context, offerFilters),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(offerCitiesProvider);
          try {
            await ref.refresh(offersProvider.future);
          } catch (e) {
            // Error is handled by the provider state
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (offerFilters.hasFilters)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (offerFilters.city != null)
                          _buildActiveFilterChip(
                            offerFilters.city!,
                            () => ref.read(offerFilterProvider.notifier).updateFilters(offerFilters.copyWith(clearCity: true)),
                          ),
                        if (offerFilters.category != null)
                          _buildActiveFilterChip(
                            offerFilters.category!,
                            () => ref.read(offerFilterProvider.notifier).updateFilters(offerFilters.copyWith(clearCategory: true)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            offersAsyncValue.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return SliverFillRemaining(
                    child: const Center(
                      child: Text('No deals available for this city.', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notifier = ref.watch(offersProvider.notifier);
                      if (index == offers.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildDealCard(context, ref, offers[index], claimedOffersAsyncValue);
                    },
                    childCount: offers.length + (ref.watch(offersProvider.notifier).isFetchingMore ? 1 : 0),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            )
          ],
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

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBrand.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBrand.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.primaryBrand, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.primaryBrand),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, WidgetRef ref, OfferModel offer, AsyncValue<List<ClaimedOfferModel>> claimedOffersState) {
    bool isClaimed = false;
    if (claimedOffersState is AsyncData) {
      isClaimed = claimedOffersState.value!.any((c) => c.offerId == offer.id);
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CouponDetailsScreen(offer: offer)));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_offer, color: AppColors.primaryBrand),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                  if (offer.subtitle.isNotEmpty)
                    Text(offer.subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 12, color: AppColors.primaryBrand),
                      const SizedBox(width: 4),
                      Text(offer.type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on, size: 12, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Text(offer.city ?? '', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(offer.description, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isClaimed 
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : SecondaryButton(
                    text: 'Claim',
                    width: 80,
                    height: 32,
                    fontSize: 12,
                    onPressed: () async {
                      try {
                        await ref.read(claimedOffersListProvider.notifier).claim(offer.id);
                        if(mounted) {
                          CustomToast.showSuccess(context, 'Offer claimed! Check Claimed offers.');
                        }
                      } catch (e) {
                         if(mounted) {
                          CustomToast.showError(context, 'Failed to claim offer.');
                        }
                      }
                    },
                  )
          ],
        ),
      ),
    );
  }
  
  Widget _buildClaimedDealCard(OfferModel offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        border: Border.all(color: AppColors.success),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(offer.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(offer.description, style: const TextStyle(fontSize: 14, color: AppColors.secondaryText)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid)
            ),
            child: Column(
              children: [
                const Text('DISCOUNT CODE', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                const SizedBox(height: 4),
                Text(offer.discountCode ?? 'N/A', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBrand, letterSpacing: 2)),
              ],
            )
          )
        ],
      ),
    );
  }
}

// RewardScratchCard left intentionally for future backward compatibility if needed, though removed from main view to keep things simple
class RewardScratchCard extends StatefulWidget {
  final String id;
  final Color topColor;
  final String content;

  const RewardScratchCard({super.key, required this.id, required this.topColor, required this.content});

  @override
  State<RewardScratchCard> createState() => _RewardScratchCardState();
}

class _RewardScratchCardState extends State<RewardScratchCard> {
  bool isScratched = false;
  final scratchKey = GlobalKey<ScratcherState>();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
