import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  
  ChatMessage({required this.text, required this.isUser});
}

class ChatResumeNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text: 'Hi there! I am the Career Setu AI assistant. I can help you build your resume. Let\'s start by getting your work experience. What was your most recent job title?',
        isUser: false,
      )
    ];
  }

  void sendMessage(String text) async {
    // Add user message
    state = [...state, ChatMessage(text: text, isUser: true)];

    // Simulate AI response delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple mock logic for AI responses
    String aiResponse;
    if (state.length == 2) {
      aiResponse = 'Great! How long did you work there? (e.g., 2020-2023)';
    } else if (state.length == 4) {
      aiResponse = 'Got it. Can you describe one major accomplishment in that role?';
    } else if (state.length == 6) {
      aiResponse = 'Excellent. What are your top 3 skills?';
    } else {
      aiResponse = 'Awesome! I have enough information to generate your resume. Click the "Generate Resume" button above when you are ready.';
    }

    state = [...state, ChatMessage(text: aiResponse, isUser: false)];
  }
}

final chatResumeProvider = NotifierProvider<ChatResumeNotifier, List<ChatMessage>>(() {
  return ChatResumeNotifier();
});
