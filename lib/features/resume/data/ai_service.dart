import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../jobs/data/jobs_repository.dart';
import '../domain/chat_message.dart';
import '../domain/resume_draft.dart';

class ResumeChatResult {
  final List<ChatMessage> messages;
  final ResumeDraft draft;
  final String stage;

  ResumeChatResult({required this.messages, required this.draft, required this.stage});

  factory ResumeChatResult.fromJson(Map<String, dynamic> json) => ResumeChatResult(
        messages: (json['messages'] as List? ?? [])
            .whereType<Map>()
            .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        draft: ResumeDraft.fromJson(json['draft'] is Map ? Map<String, dynamic>.from(json['draft']) : null),
        stage: json['stage']?.toString() ?? 'new',
      );
}

/// Talks to the backend AI resume builder. The OpenAI key lives only on the server.
class AIService {
  final ApiClient _apiClient;

  AIService(this._apiClient);

  static final _aiOptions = Options(receiveTimeout: const Duration(seconds: 90));

  Future<ResumeChatResult> getSession() async {
    final response = await _apiClient.get('/resume/session');
    return ResumeChatResult.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<ResumeChatResult> reset() async {
    final response = await _apiClient.post('/resume/session/reset');
    return ResumeChatResult.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// [event] is 'init', 'message', 'choice' or 'upload'.
  Future<ResumeChatResult> chat(
    String event, {
    String? text,
    String? choice,
    Map<String, String>? file,
    ProgressCallback? onSendProgress,
  }) async {
    final response = await _apiClient.post(
      '/resume/chat',
      data: {
        'event': event,
        if (text != null) 'text': text,
        if (choice != null) 'choice': choice,
        if (file != null) 'file': file,
      },
      options: _aiOptions,
      onSendProgress: onSendProgress,
    );
    return ResumeChatResult.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<ResumeDraft> saveDraft(ResumeDraft draft) async {
    final response = await _apiClient.put('/resume/draft', data: {'draft': draft.toJson()});
    return ResumeDraft.fromJson(Map<String, dynamic>.from(response.data['draft'] ?? {}));
  }

  /// Rewrites a summary (returns one string) or bullets (returns a list) with AI.
  Future<List<String>> improve(String kind, String text, {String context = ''}) async {
    final response = await _apiClient.post(
      '/resume/improve',
      data: {'kind': kind, 'text': text, 'context': context},
      options: _aiOptions,
    );
    final data = Map<String, dynamic>.from(response.data);
    if (kind == 'bullets') return List<String>.from(data['bullets'] ?? []);
    return [data['text']?.toString() ?? ''];
  }
}

final aiServiceProvider = Provider((ref) => AIService(ref.watch(apiClientProvider)));
