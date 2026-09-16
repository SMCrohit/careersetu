import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../domain/banner_model.dart';
import '../../jobs/data/jobs_repository.dart';

class BannersRepository {
  final ApiClient _apiClient;

  BannersRepository(this._apiClient);

  Future<List<BannerModel>> fetchBanners() async {
    final response = await _apiClient.get('/banners');
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => BannerModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load banners');
    }
  }
}

final bannersRepositoryProvider = Provider<BannersRepository>((ref) {
  return BannersRepository(ref.watch(apiClientProvider));
});
