import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  Future<Map<String, dynamic>> processResumeStep(String userInput, String currentStep, Map<String, dynamic> currentResumeData) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found in .env file.');
    }

    String systemPrompt = '''
You are an expert professional resume writer interviewing a user.
The current section you are gathering information for is: $currentStep.
The user's current resume data is: ${jsonEncode(currentResumeData)}.

Evaluate the user's latest input: "$userInput"

1. If the input is too brief, vague, or invalid (e.g. they say "hi", "yes", or give a 1-word answer for work history), ask a polite follow-up question to get more details for the $currentStep. DO NOT extract data, and keep next_step as "$currentStep".
2. If the input provides good information for the $currentStep, extract and professionalize it into "extracted_data". Then, decide what the next step should be (e.g. summary -> experience -> education -> skills -> complete). Formulate a "reply" asking them for information about the "next_step".

For "extracted_data", YOU MUST strictly follow this JSON schema depending on the current section:
- If section is "summary": Return a single string.
- If section is "experience": Return a LIST OF OBJECTS, where each object has: "title" (string), "company" (string), "date" (string), "bullets" (list of strings).
- If section is "education": Return a LIST OF OBJECTS, where each object has: "degree" (string), "date" (string), "school" (string).
- If section is "skills": Return a single string with skills separated by commas or newlines.

Return your response ONLY as a JSON object with:
- "is_sufficient": boolean (true if you got enough info to move to the next section, false if you need to ask more about the current section)
- "reply": Your conversational response to the user.
- "extracted_data": (Optional) The professionalized data matching the schema above. Only provide this if is_sufficient is true.
- "next_step": The string key of the next section to move to ("summary", "experience", "education", "skills", "complete"). If is_sufficient is false, next_step MUST be "$currentStep".

Do not wrap the JSON in Markdown code blocks like ```json, just return the raw JSON object.
''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userInput}
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final String content = jsonResponse['choices'][0]['message']['content'].toString().trim();
      
      // Clean up markdown if the model accidentally included it
      String cleanedContent = content;
      if (cleanedContent.startsWith('```json')) {
        cleanedContent = cleanedContent.replaceAll('```json', '');
        cleanedContent = cleanedContent.replaceAll('```', '');
      }
      
      return jsonDecode(cleanedContent);
    } else {
      throw Exception('Failed to communicate with AI: \${response.body}');
    }
  }
}
