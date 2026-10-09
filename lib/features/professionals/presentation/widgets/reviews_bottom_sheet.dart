import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../domain/professional_model.dart';
import '../../domain/professional_review_model.dart';
import '../providers/professional_reviews_provider.dart';

/// All reviews for a professional, in the Profile bottom-sheet style.
class ReviewsBottomSheet extends ConsumerWidget {
  final Professional professional;

  const ReviewsBottomSheet({super.key, required this.professional});

  static void show(BuildContext context, Professional professional) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewsBottomSheet(professional: professional),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(professionalReviewsProvider(professional.id));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ratings & reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppUi.ink)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 4),
                        Text(professional.ratingLabel, style: AppText.value),
                        Text('  ·  ${professional.reviews} ${professional.reviews == 1 ? 'review' : 'reviews'}', style: AppText.label),
                      ]),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Flexible(
            child: reviews.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppUi.accent))),
              error: (_, __) => const Padding(padding: EdgeInsets.all(32), child: Text('Could not load reviews.', style: AppText.subtitle)),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No reviews yet. Be the first after your session!', textAlign: TextAlign.center, style: AppText.subtitle),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => ReviewTile(review: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One review card, also used for the preview on the details screen.
class ReviewTile extends StatelessWidget {
  final ProfessionalReview review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final name = review.userName ?? 'Student';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppUi.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppUi.iconTile,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: AppText.value.copyWith(fontSize: 13, color: const Color(0xFF0369A1))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: AppText.value.copyWith(fontSize: 13.5))),
              ...List.generate(5, (i) => Icon(i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16, color: i < review.rating.round() ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1))),
            ],
          ),
          if ((review.comment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!.trim(), style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.secondaryText)),
          ],
        ],
      ),
    );
  }
}
