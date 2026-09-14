import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scratcher/scratcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../providers/offers_provider.dart';
import '../../domain/offer_model.dart';
import 'coupon_details_screen.dart';

class OffersHubScreen extends ConsumerStatefulWidget {
  const OffersHubScreen({super.key});

  @override
  ConsumerState<OffersHubScreen> createState() => _OffersHubScreenState();
}

class _OffersHubScreenState extends ConsumerState<OffersHubScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Offers';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offersAsyncValue = ref.watch(offersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search offers, deals...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {});
                },
              )
            : const Text('Local Offers', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.primaryText),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Rewards', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text('Earn scratch cards by applying to jobs.', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  _buildScratchCard(const [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)], '₹500 Amazon Gift Card', true, context)
                ],
              ),
            ),
            
            Container(
              color: AppColors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categories', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All Offers'),
                        _buildCategoryChip('Groceries'),
                        _buildCategoryChip('Dining'),
                        _buildCategoryChip('Services'),
                        _buildCategoryChip('Education'),
                        _buildCategoryChip('Loans'),
                      ],
                    ),
                  )
                ],
              ),
            ),

            Container(
              color: AppColors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nearby Deals', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 16),
                  offersAsyncValue.when(
                    data: (offers) {
                      final query = _searchController.text.toLowerCase();
                      final filtered = offers.where((offer) {
                        final matchesCategory = _selectedCategory == 'All Offers' || offer.type == _selectedCategory;
                        final matchesSearch = offer.title.toLowerCase().contains(query) || offer.subtitle.toLowerCase().contains(query);
                        return matchesCategory && matchesSearch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('No deals found.', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                          ),
                        );
                      }

                      return Column(
                        children: filtered.map((offer) => _buildDealCard(context, ref, offer)).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScratchCard(List<Color> colors, String content, bool isHidden, BuildContext context) {
    return RewardScratchCard(
      id: 'reward_${content.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
      topColor: colors.first, // Using the first color of the gradient for simplicity
      content: content,
    );
  }

  Widget _buildCategoryChip(String label) {
    final selected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.success : AppColors.white,
          border: Border.all(color: selected ? AppColors.success : AppColors.secondaryText),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, WidgetRef ref, OfferModel offer) {
    final claimedOffers = ref.watch(claimedOffersProvider);
    final isClaimed = claimedOffers.contains(offer.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CouponDetailsScreen(offer: offer)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
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
                  Text(offer.subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBrand)),
                  Text(offer.description, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                ],
              ),
            ),
            isClaimed 
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : SecondaryButton(
                    text: offer.action,
                    width: 80,
                    height: 32,
                    fontSize: 12,
                    onPressed: () {
                      ref.read(claimedOffersProvider.notifier).claimOffer(offer.id);
                      CustomToast.showSuccess(context, 'Offer ${offer.action}ed successfully!');
                    },
                  )
          ],
        ),
      ),
    );
  }
}

class RewardScratchCard extends ConsumerStatefulWidget {
  final String id;
  final Color topColor;
  final String content;

  const RewardScratchCard({
    super.key,
    required this.id,
    required this.topColor,
    required this.content,
  });

  @override
  ConsumerState<RewardScratchCard> createState() => _RewardScratchCardState();
}

class _RewardScratchCardState extends ConsumerState<RewardScratchCard> {
  final _scratchKey = GlobalKey<ScratcherState>();
  bool _isRevealed = false;
  bool _isScratching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(scratchedRewardsProvider).contains(widget.id)) {
        setState(() => _isRevealed = true);
      }
    });
  }

  void _onScratchComplete() {
    if (!_isRevealed) {
      _scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 300));
      setState(() => _isRevealed = true);
      ref.read(scratchedRewardsProvider.notifier).markAsScratched(widget.id);
      CustomToast.showSuccess(context, 'You unlocked a new reward!');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRevealed) {
      // Show revealed state
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.content, style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('CONGRATULATIONS!', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Scratcher(
              key: _scratchKey,
              brushSize: 50,
              threshold: 30, // 30% as requested
              color: widget.topColor,
              onThreshold: () => _onScratchComplete(),
              onChange: (value) {
                if (!_isScratching && value > 0) {
                  setState(() => _isScratching = true);
                }
              },
              child: Container(
                color: const Color(0xFF1E293B),
                width: double.infinity,
                height: 160,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.content, style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text('CONGRATULATIONS!', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            // The "Tap to Reveal" overlay text that disappears once scratching starts
            if (!_isScratching && !_isRevealed)
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      // Decorative elements for realistic digital scratch card look
                      Positioned(top: -30, right: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),
                      Positioned(bottom: -20, left: -10, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),
                      Positioned(top: 20, left: 20, child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)))),
                      Positioned(bottom: 30, right: 40, child: Container(width: 15, height: 15, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)))),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 12),
                            const Text('You won a reward!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text('Scratch to reveal', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
