import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';

class AIService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getResumeSession() async {
    final response = await _apiClient.get('/resume/session');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to get resume session: ${response.data}');
    }
  }

  Future<void> updateResumeSession({
    List<Map<String, String>>? chatHistory,
    Map<String, dynamic>? extractedData,
    Map<String, dynamic>? uploadedResumeInfo,
    String? status,
    String? currentStep,
  }) async {
    final Map<String, dynamic> body = {};
    if (chatHistory != null) body['chat_history'] = chatHistory;
    if (extractedData != null) body['extracted_data'] = extractedData;
    if (uploadedResumeInfo != null) body['uploaded_resume_info'] = uploadedResumeInfo;
    if (status != null) body['status'] = status;
    if (currentStep != null) body['current_step'] = currentStep;

    final response = await _apiClient.post('/resume/session/update', data: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to update resume session: ${response.data}');
    }
  }

  Future<Map<String, dynamic>> processResumeStep(String userInput, String currentStep, Map<String, dynamic> currentResumeData, List<Map<String, String>> chatHistory) async {
    final baseUrl = ApiClient.baseUrl;
    
    if (baseUrl.isEmpty) {
      throw Exception('Base URL is empty.');
    }

    final endpoint = '$baseUrl/resume/process-step';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_input': userInput,
        'current_step': currentStep,
        'current_resume_data': currentResumeData,
        'chat_history': chatHistory,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to communicate with backend: ${response.body}');
    }
  }
}
