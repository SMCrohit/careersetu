import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/banner_model.dart';
import '../../data/banners_repository.dart';

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final repository = ref.watch(bannersRepositoryProvider);
  return repository.fetchBanners();
});
