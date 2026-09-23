import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/test_model.dart';
import '../../jobs/data/jobs_repository.dart'; // To reuse apiClientProvider

class TestsRepository {
  final ApiClient _apiClient;

  TestsRepository(this._apiClient);

  Future<List<TestModel>> fetchAllTests() async {
    final response = await _apiClient.get('/tests');
    final List<dynamic> testsJson = response.data;
    return testsJson
        .map((e) => TestModel.fromJson(e))
        .where((test) => test.questions.isNotEmpty)
        .toList();
  }

  Future<TestModel> fetchTest(String id) async {
    final response = await _apiClient.get('/tests/$id');
    return TestModel.fromJson(response.data);
  }
}

final testsRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TestsRepository(apiClient);
});
