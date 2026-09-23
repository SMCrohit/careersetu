import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/professional_model.dart';
import '../providers/professional_reviews_provider.dart';

class ReviewsBottomSheet extends ConsumerWidget {
  final Professional professional;

  const ReviewsBottomSheet({super.key, required this.professional});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsyncValue = ref.watch(professionalReviewsProvider(professional.id));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ratings & Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.secondaryBrand, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${professional.rating} / 5.0',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.secondaryText),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          
          // Reviews List
          Flexible(
            child: reviewsAsyncValue.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No user reviews yet.', style: TextStyle(color: AppColors.secondaryText)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: AppColors.backgroundLight),
                  ),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.userName ?? 'Anonymous User',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryText),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.secondaryBrand, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  review.rating.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryText),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (review.comment != null && review.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            review.comment!,
                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
                          ),
                        ]
                      ],
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(40),
                child: Center(child: Text('Error loading reviews.', style: TextStyle(color: AppColors.error))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
