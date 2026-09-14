import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/offer_model.dart';
import '../providers/offers_provider.dart';

class CouponDetailsScreen extends ConsumerWidget {
  final OfferModel offer;

  const CouponDetailsScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimedOffers = ref.watch(claimedOffersProvider);
    final isClaimed = claimedOffers.contains(offer.id);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(offer.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      offer.subtitle,
                      style: const TextStyle(fontSize: 32, color: AppColors.primaryBrand, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(offer.type, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildPromoBanner('Limited Time', 'Zero Processing Fees', 'Apply for higher education with no hidden charges.', const Color(0xFFFF3366)),
                  _buildPromoBanner('Fast Track', 'Instant Approval', 'Get approved up to ₹10L for verified universities instantly.', const Color(0xFF00C853)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Terms & Conditions', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Applicable for domestic and international courses.'),
                  _buildBulletPoint('Co-applicant required for loans above ₹5,00,000.'),
                  _buildBulletPoint('Offer valid until end of the year.'),
                  
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: isClaimed ? 'Claimed' : 'Apply Now',
                    onPressed: isClaimed 
                        ? null 
                        : () {
                            ref.read(claimedOffersProvider.notifier).claimOffer(offer.id);
                            CustomToast.showSuccess(context, 'Successfully applied to ${offer.title}!');
                          },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(String tag, String title, String subtitle, Color tagColor) {
    return Container(
      width: 300,
      height: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }
}
