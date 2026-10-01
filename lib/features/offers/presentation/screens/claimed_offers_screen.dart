import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/offers_provider.dart';
import '../../domain/offer_model.dart';

class ClaimedOffersScreen extends ConsumerStatefulWidget {
  const ClaimedOffersScreen({super.key});

  @override
  ConsumerState<ClaimedOffersScreen> createState() => _ClaimedOffersScreenState();
}

class _ClaimedOffersScreenState extends ConsumerState<ClaimedOffersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(claimedOffersListProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claimedOffersAsyncValue = ref.watch(claimedOffersListProvider);
    final notifier = ref.watch(claimedOffersListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Claimed Offers', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(claimedOffersListProvider.future);
        },
        child: claimedOffersAsyncValue.when(
          data: (claimedOffers) {
            if (claimedOffers.isEmpty) {
               return ListView(
                 children: const [
                   SizedBox(height: 100),
                   Center(child: Text('You have not claimed any offers yet.', style: TextStyle(color: AppColors.secondaryText, fontSize: 16))),
                 ],
               );
            }
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: claimedOffers.length + (notifier.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == claimedOffers.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final item = claimedOffers[index];
                final offer = item.offer;
                if (offer == null) return const SizedBox.shrink();
                
                return _buildClaimedDealCard(offer);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildClaimedDealCard(OfferModel offer) {
    final bool hasCode = offer.discountCode != null && offer.discountCode!.isNotEmpty;
    return Container(
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
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.success),
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
                if (hasCode) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.highlight.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.highlight.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer, size: 14, color: AppColors.highlight),
                        const SizedBox(width: 8),
                        Text(
                          offer.discountCode!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppColors.highlight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
