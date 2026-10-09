import 'package:dio/dio.dart' show Options;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/test_model.dart';

class TestsPage {
  final List<TestSummary> tests;
  final int total;

  const TestsPage(this.tests, this.total);
}

class TestsRepository {
  final ApiClient _apiClient;

  TestsRepository(this._apiClient);

  static const pageSize = 20;

  /// [status] is 'available' (active tests not yet taken) or 'attempted'.
  Future<TestsPage> fetchTests({String status = 'available', int page = 1}) async {
    final response = await _apiClient.get('/tests', queryParameters: {'status': status, 'page': page, 'limit': pageSize});
    final data = Map<String, dynamic>.from(response.data);
    final tests = (data['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => TestSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return TestsPage(tests, (data['total'] as num?)?.toInt() ?? tests.length);
  }

  /// Questions for taking the test (answers are not included).
  Future<ActiveTest> startTest(String testId) async {
    final response = await _apiClient.post('/tests/$testId/start');
    return ActiveTest.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// Sends answers for server-side grading. Returns the graded result with the AI summary.
  Future<AttemptResult> submitAttempt({
    required String testId,
    required int timeTakenSeconds,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _apiClient.post(
      '/users/me/test-attempts',
      data: {'test_id': testId, 'time_taken_seconds': timeTakenSeconds, 'answers': answers},
      // Grading plus the AI summary can take longer than the default timeout.
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    return AttemptResult.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<AttemptResult> fetchAttempt(String attemptId) async {
    final response = await _apiClient.get('/users/me/test-attempts/$attemptId');
    return AttemptResult.fromJson(Map<String, dynamic>.from(response.data));
  }
}

final testsRepositoryProvider = Provider((ref) => TestsRepository(ref.watch(apiClientProvider)));
