import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../providers/offers_provider.dart';
import '../../domain/offer_model.dart';

class ClaimedOffersScreen extends ConsumerStatefulWidget {
  const ClaimedOffersScreen({super.key});

  @override
  ConsumerState<ClaimedOffersScreen> createState() => _ClaimedOffersScreenState();
}

class _ClaimedOffersScreenState extends ConsumerState<ClaimedOffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(claimedOffersListProvider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claimedOffersAsyncValue = ref.watch(claimedOffersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Rewards & Passes',
          style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBrand,
          unselectedLabelColor: AppColors.secondaryText,
          indicatorColor: AppColors.primaryBrand,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Active Passes & Codes'),
            Tab(text: 'Used / History'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(claimedOffersListProvider);
            await ref.read(claimedOffersListProvider.future);
          },
          child: claimedOffersAsyncValue.when(
            data: (claimedOffers) {
              final activeClaims = claimedOffers.where((c) => c.status != 'redeemed').toList();
              final redeemedClaims = claimedOffers.where((c) => c.status == 'redeemed').toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildClaimList(activeClaims, isActiveTab: true),
                  _buildClaimList(redeemedClaims, isActiveTab: false),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading claimed offers: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimList(List<ClaimedOfferModel> items, {required bool isActiveTab}) {
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(
                  isActiveTab ? Icons.confirmation_number_outlined : Icons.history,
                  size: 48,
                  color: AppColors.borderDark,
                ),
                const SizedBox(height: 12),
                Text(
                  isActiveTab ? 'No active passes or vouchers.' : 'No redeemed history yet.',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  isActiveTab 
                      ? 'Browse the Offers Hub and claim deals from gyms, banks, and classes.'
                      : 'When you use an in-store pass, mark it as redeemed here.',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(top: 12, bottom: MediaQuery.paddingOf(context).bottom + 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildClaimCard(item, isActive: isActiveTab);
      },
    );
  }

  Widget _buildClaimCard(ClaimedOfferModel item, {required bool isActive}) {
    final offer = item.offer;
    final code = item.voucherCode ?? offer?.discountCode ?? 'CLAIMED';
    final isPass = code.startsWith('PASS-') || (offer?.redemptionType == 'in_store_pass');
    final isLead = code.startsWith('LEAD-') || (offer?.redemptionType == 'bank_lead');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? AppColors.border : AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive 
                  ? (isPass ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4))
                  : AppColors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (isActive) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isPass ? const Color(0xFFD97706) : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPass ? 'DIGITAL IN-STORE PASS' : (isLead ? 'APPLICATION SUBMITTED' : 'ACTIVE COUPON'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPass ? const Color(0xFFB45309) : (isLead ? const Color(0xFF047857) : AppColors.success),
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.check_circle, size: 14, color: AppColors.secondaryText),
                  const SizedBox(width: 6),
                  const Text(
                    'REDEEMED',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
                  ),
                ],
                const Spacer(),
                if (offer?.city != null && offer!.city!.isNotEmpty)
                  Text(
                    offer.city!,
                    style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                  ),
              ],
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner Name & Title
                if (offer?.merchantName != null && offer!.merchantName!.isNotEmpty)
                  Text(
                    offer.merchantName!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBrand),
                  ),
                Text(
                  offer?.title ?? 'Claimed Perk',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                ),
                if (offer?.subtitle != null && offer!.subtitle.isNotEmpty)
                  Text(
                    offer.subtitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                  ),

                const SizedBox(height: 12),

                // Digital Pass / Code Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isPass ? 'SHOW THIS CODE AT COUNTER' : (isLead ? 'PARTNER REFERENCE ID' : 'COUPON CODE'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryText, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SelectableText(
                            code,
                            style: TextStyle(
                              fontSize: isPass ? 18 : 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                              color: isActive ? AppColors.primaryBrand : AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16, color: AppColors.primaryBrand),
                            tooltip: 'Copy Code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              CustomToast.showSuccess(context, 'Copied to clipboard!');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Merchant Address for In-store Passes
                if (offer?.merchantAddress != null && offer!.merchantAddress!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.pin_drop, size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          offer.merchantAddress!,
                          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ),
                    ],
                  ),
                ],

                // Action Buttons (Mark as Used / Redeem)
                if (isActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (offer?.externalUrl != null && offer!.externalUrl!.isNotEmpty) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryBrand),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.primaryBrand),
                            label: const Text('Open Partner Site', style: TextStyle(color: AppColors.primaryBrand, fontSize: 12)),
                            onPressed: () async {
                              final uri = Uri.parse(offer.externalUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Mark as Redeemed?'),
                                content: const Text('Confirm that you have used this pass at the counter or partner portal?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Redeemed')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(claimedOffersListProvider.notifier).redeem(item.id);
                              if (mounted) {
                                CustomToast.showSuccess(context, 'Marked as redeemed!');
                              }
                            }
                          },
                          child: const Text('Mark as Used', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
