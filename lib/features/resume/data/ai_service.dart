import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';

class AIService {
  Future<Map<String, dynamic>> processResumeStep(String userInput, String currentStep, Map<String, dynamic> currentResumeData) async {
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
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to communicate with backend: ${response.body}');
    }
  }
}
