import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../jobs/data/jobs_repository.dart';
import '../domain/resume_analysis.dart';

class ResumeAnalysisRepository {
  final ApiClient _apiClient;

  ResumeAnalysisRepository(this._apiClient);

  /// Sends the resume to the backend, which reads it with AI and compares it with the profile.
  /// Nothing is saved. Throws [ApiException] with a user-facing message on failure.
  Future<ResumeAnalysis> analyzeResume(
    String filename,
    String base64Data, {
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _apiClient.post(
        '/resume/analyze',
        data: {'filename': filename, 'data': base64Data},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return ResumeAnalysis.fromJson(Map<String, dynamic>.from(response.data));
    } on ApiException catch (e) {
      if (e.statusCode == 502 || e.statusCode == 503) {
        throw ApiException("AI couldn't read your resume right now. Please try again.", statusCode: e.statusCode);
      }
      rethrow;
    }
  }
}

final resumeAnalysisRepositoryProvider = Provider((ref) {
  return ResumeAnalysisRepository(ref.watch(apiClientProvider));
});
