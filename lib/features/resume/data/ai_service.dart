import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  Future<Map<String, dynamic>> processResumeStep(String userInput, String currentStep, Map<String, dynamic> currentResumeData) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file.');
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
