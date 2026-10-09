import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/availability.dart';
import '../domain/professional_filter_state.dart';
import '../domain/professional_model.dart';
import '../domain/professional_review_model.dart';

class ProfessionalsPage {
  final List<Professional> items;
  final int total;

  const ProfessionalsPage(this.items, this.total);
}

class ProfessionalFilterOptions {
  final List<String> professions;
  final List<String> cities;
  final List<String> languages;
  final List<String> consultationModes;
  final int feeMin;
  final int feeMax;

  const ProfessionalFilterOptions({
    this.professions = const [],
    this.cities = const [],
    this.languages = const [],
    this.consultationModes = const ['In-Person', 'Online', 'Phone'],
    this.feeMin = 0,
    this.feeMax = 5000,
  });
}

/// 'doctor' (Health & Wellness) or 'non_doctor' (Professionals).
enum ProfessionalGroup {
  doctor('doctor'),
  nonDoctor('non_doctor');

  final String api;
  const ProfessionalGroup(this.api);
}

class ProfessionalsRepository {
  final ApiClient _apiClient;

  ProfessionalsRepository(this._apiClient);

  static const pageSize = 10;

  Future<ProfessionalsPage> fetchProfessionals({
    int page = 1,
    int limit = pageSize,
    String query = '',
    ProfessionalFilterState filters = const ProfessionalFilterState(),
    ProfessionalGroup? group,
    bool featuredOnly = false,
  }) async {
    final response = await _apiClient.get('/professionals', queryParameters: {
      'page': page,
      'limit': limit,
      if (query.trim().isNotEmpty) 'search': query.trim(),
      if (group != null) 'group': group.api,
      if (featuredOnly) 'featured': true,
      ...filters.toQuery(),
    });
    final data = Map<String, dynamic>.from(response.data);
    final items = (data['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Professional.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return ProfessionalsPage(items, (data['total'] as num?)?.toInt() ?? items.length);
  }

  Future<Professional> fetchProfessional(String id) async {
    final response = await _apiClient.get('/professionals/$id');
    return Professional.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<ProfessionalFilterOptions> fetchFilterOptions() async {
    final response = await _apiClient.get('/professionals/filters');
    final d = Map<String, dynamic>.from(response.data);
    List<String> list(String key) => (d[key] as List? ?? []).map((e) => e.toString()).toList();
    final modes = list('consultation_modes');
    return ProfessionalFilterOptions(
      professions: list('professions'),
      cities: list('cities'),
      languages: list('languages'),
      consultationModes: modes.isNotEmpty ? modes : const ['In-Person', 'Online', 'Phone'],
      feeMin: (d['fee_min'] as num?)?.floor() ?? 0,
      feeMax: (d['fee_max'] as num?)?.ceil() ?? 5000,
    );
  }

  /// Dates with open slots in the next 30 days.
  Future<List<AvailableDate>> fetchAvailability(String id) async {
    final response = await _apiClient.get('/professionals/$id/availability');
    final dates = (Map<String, dynamic>.from(response.data)['dates'] as List? ?? []);
    return dates.whereType<Map>().map((e) => AvailableDate.fromJson(Map<String, dynamic>.from(e))).whereType<AvailableDate>().toList();
  }

  Future<List<ProfessionalReview>> fetchReviews(String professionalId) async {
    final response = await _apiClient.get('/professionals/$professionalId/reviews');
    return (response.data as List).map((json) => ProfessionalReview.fromJson(json)).toList();
  }

  Future<ProfessionalReview?> getMyReview(String professionalId) async {
    try {
      final response = await _apiClient.get('/users/me/professionals/$professionalId/review');
      return ProfessionalReview.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<ProfessionalReview> submitReview(String professionalId, double rating, String comment) async {
    final response = await _apiClient.post(
      '/users/me/professionals/$professionalId/review',
      data: {'rating': rating, 'comment': comment},
    );
    return ProfessionalReview.fromJson(response.data);
  }
}

final professionalsRepositoryProvider = Provider<ProfessionalsRepository>((ref) {
  return ProfessionalsRepository(ref.watch(apiClientProvider));
});
