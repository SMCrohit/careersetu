import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scratcher/scratcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/offer_model.dart';
import '../providers/offers_provider.dart';
import 'claimed_offers_screen.dart';

class CouponDetailsScreen extends ConsumerStatefulWidget {
  final OfferModel offer;

  const CouponDetailsScreen({super.key, required this.offer});

  @override
  ConsumerState<CouponDetailsScreen> createState() => _CouponDetailsScreenState();
}

class _CouponDetailsScreenState extends ConsumerState<CouponDetailsScreen> {
  bool _isClaiming = false;

  void _handleClaim() async {
    if (widget.offer.redemptionType == 'bank_lead') {
      _showLeadInquirySheet();
    } else {
      _executeClaim();
    }
  }

  void _showLeadInquirySheet() {
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.success, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Partner Inquiry Request',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.offer.merchantName ?? widget.offer.title} will reach out to verify your details and guide your application.',
                style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              const Text('Alternative Contact / WhatsApp (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'e.g. 9876543210',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Notes or Specific Query (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Looking for Master degree loan, evening demo batch, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Submit Request & Get Reference ID',
                onPressed: () {
                  Navigator.pop(ctx);
                  _executeClaim(inquiryDetails: {
                    if (phoneController.text.trim().isNotEmpty) 'phone': phoneController.text.trim(),
                    if (notesController.text.trim().isNotEmpty) 'notes': notesController.text.trim(),
                  });
                },
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeClaim({Map<String, dynamic>? inquiryDetails}) async {
    setState(() => _isClaiming = true);
    try {
      final res = await ref.read(claimedOffersListProvider.notifier).claim(
        widget.offer.id,
        inquiryDetails: inquiryDetails,
      );

      final assignedCode = res['voucher_code'] ?? res['discount_code'] ?? 'CLAIMED';

      if (mounted) {
        _showScratchCardDialog(assignedCode);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Failed to claim offer. It may have expired or reached quota limit.');
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  void _showScratchCardDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, color: Color(0xFFD97706), size: 40),
                const SizedBox(height: 8),
                const Text(
                  'Deal Unlocked!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scratch the card below to reveal your pass / voucher code:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 16),

                // Scratch Card Element
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Scratcher(
                    brushSize: 45,
                    threshold: 35,
                    color: AppColors.primaryBrand,
                    accuracy: ScratchAccuracy.low,
                    onChange: (value) {},
                    onThreshold: () {
                      HapticFeedback.mediumImpact();
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: const Color(0xFFF0FDF4),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'YOUR VOUCHER / PASS ID',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            code,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                              color: AppColors.primaryBrand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'This offer has been added to "My Rewards" wallet.',
                  style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          CustomToast.showSuccess(context, 'Copied to clipboard!');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Copy Code', style: TextStyle(color: AppColors.primaryText)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrand,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const ClaimedOffersScreen()),
                          );
                        },
                        child: const Text('View Pass', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimedOffersState = ref.watch(claimedOffersListProvider);
    bool isClaimed = false;
    if (claimedOffersState is AsyncData && claimedOffersState.value != null) {
      isClaimed = claimedOffersState.value!.any((c) => c.offerId == widget.offer.id);
    }

    final offer = widget.offer;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: AppColors.white,
        title: Text(
          offer.merchantName ?? offer.title,
          style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryBrand.withValues(alpha: 0.05),
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & City Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBrand,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          offer.type.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (offer.city != null && offer.city!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: AppColors.secondaryText),
                              const SizedBox(width: 2),
                              Text(offer.city!, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    offer.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle
                  if (offer.subtitle.isNotEmpty)
                    Text(
                      offer.subtitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                    ),

                  const SizedBox(height: 12),

                  // Scarcity or Expiry
                  if (offer.totalQuota != null || offer.validUntil != null)
                    Row(
                      children: [
                        if (offer.totalQuota != null) ...[
                          const Icon(Icons.local_fire_department, size: 16, color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.claimedCount} / ${offer.totalQuota} Claimed',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepOrange),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (offer.validUntil != null) ...[
                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            'Valid until ${offer.validUntil!.split('T')[0]}',
                            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ],
                    )
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant / Partner Info
                  if (offer.merchantName != null && offer.merchantName!.isNotEmpty) ...[
                    const Text('Partner Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront, color: AppColors.primaryBrand, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(offer.merchantName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          ),
                          if (offer.merchantAddress != null && offer.merchantAddress!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.pin_drop, size: 14, color: AppColors.secondaryText),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(offer.merchantAddress!, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                ),
                              ],
                            ),
                          ],
                          if (offer.partnerPhone != null && offer.partnerPhone!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: AppColors.secondaryText),
                                const SizedBox(width: 6),
                                Text(offer.partnerPhone!, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                              ],
                            ),
                          ],
                          if ((offer.targetProfessions != null && offer.targetProfessions!.isNotEmpty) || (offer.targetStream != null && offer.targetStream != 'All')) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.work_outline, size: 14, color: AppColors.secondaryText),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Target: ${offer.targetProfessions ?? offer.targetStream}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  const Text('About this Offer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  const SizedBox(height: 8),
                  Text(
                    offer.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.secondaryText, height: 1.5),
                  ),

                  const SizedBox(height: 20),

                  // Terms & Conditions
                  const Text('Terms & How to Redeem', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  const SizedBox(height: 8),
                  if (offer.termsAndConditions != null && offer.termsAndConditions!.isNotEmpty)
                    Text(
                      offer.termsAndConditions!,
                      style: const TextStyle(fontSize: 13, color: AppColors.secondaryText, height: 1.4),
                    )
                  else ...[
                    _buildBulletPoint('Valid for verified accounts with active identity.'),
                    _buildBulletPoint('Cannot be exchanged for cash or combined with existing partner offers.'),
                    _buildBulletPoint('Each user can claim this offer once.'),
                  ],

                  const SizedBox(height: 32),

                  // Action Button
                  if (isClaimed) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'You have already claimed this offer! Check your wallet.',
                              style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: 'Open My Rewards Wallet',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ClaimedOffersScreen()));
                      },
                    ),
                  ] else ...[
                    PrimaryButton(
                      text: _isClaiming 
                          ? 'Unlocking Offer...' 
                          : (offer.action.isNotEmpty ? offer.action : 'Claim Offer Now'),
                      onPressed: _isClaiming ? null : _handleClaim,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primaryBrand, fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
