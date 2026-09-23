import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/professional_review_model.dart';
import '../../data/professionals_repository.dart';

final professionalReviewsProvider = FutureProvider.autoDispose.family<List<ProfessionalReview>, String>((ref, professionalId) async {
  final repository = ref.watch(professionalsRepositoryProvider);
  return repository.fetchReviews(professionalId);
});
