import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/ai_service.dart';

enum ResumeStep { init, summary, experience, education, skills, complete }

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatResumeState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final Map<String, dynamic> resumeData;
  final ResumeStep currentStep;

  ChatResumeState({
    required this.messages,
    required this.isTyping,
    required this.resumeData,
    required this.currentStep,
  });

  ChatResumeState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    Map<String, dynamic>? resumeData,
    ResumeStep? currentStep,
  }) {
    return ChatResumeState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      resumeData: resumeData ?? this.resumeData,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class ChatResumeNotifier extends Notifier<ChatResumeState> {
  final AIService _aiService = AIService();

  @override
  ChatResumeState build() {
    return ChatResumeState(
      messages: [],
      isTyping: false,
      resumeData: {},
      currentStep: ResumeStep.init,
    );
  }

  bool _isResumeStrong(Map<String, dynamic> data) {
    bool hasContact = data.containsKey('full_name') && data.containsKey('email');
    bool hasSummary = data.containsKey('summary') && data['summary'].toString().isNotEmpty;
    bool hasExp = data.containsKey('experience') && (data['experience'] as List).isNotEmpty;
    bool hasEdu = data.containsKey('education') && (data['education'] as List).isNotEmpty;
    bool hasSkills = data.containsKey('skills') && (data['skills'] as List).isNotEmpty;
    
    return hasContact && hasSummary && hasExp && hasEdu && hasSkills;
  }

  void initializeChat(User? user) {
    if (user == null || state.messages.isNotEmpty) return;

    if (user.resumeData != null && _isResumeStrong(user.resumeData!)) {
      _addMessage('Hi ${user.fullName}! Your profile resume is strong enough, please look in your resume profile.', false);
      state = state.copyWith(currentStep: ResumeStep.complete, resumeData: user.resumeData!);
    } else {
      _addMessage("Hi ${user.fullName}! Let's build your resume. I already have your email and number from your profile.", false);
      _addMessage('To start, please provide a short professional summary or your career goals.', false);
      
      final initialData = Map<String, dynamic>.from(user.resumeData ?? {});
      initialData['full_name'] = user.fullName;
      initialData['email'] = user.email;
      initialData['mobile_number'] = user.mobileNumber;

      state = state.copyWith(
        currentStep: ResumeStep.summary,
        resumeData: initialData,
      );
    }
  }

  void _addMessage(String text, bool isUser) {
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: text, isUser: isUser)],
    );
  }



  String _getStepKey(ResumeStep step) {
    switch (step) {
      case ResumeStep.summary: return 'summary';
      case ResumeStep.experience: return 'experience';
      case ResumeStep.education: return 'education';
      case ResumeStep.skills: return 'skills';
      default: return 'unknown';
    }
  }

  void sendMessage(String text) async {
    if (state.currentStep == ResumeStep.complete) {
      _addMessage(text, true);
      _addMessage('Your resume is already complete! Click "Generate PDF" to view it.', false);
      return;
    }

    _addMessage(text, true);
    state = state.copyWith(isTyping: true);

    try {
      final currentStepKey = _getStepKey(state.currentStep);
      final response = await _aiService.processResumeStep(text, currentStepKey, state.resumeData);

      final String aiReply = response['reply'] ?? 'Got it!';
      final bool isSufficient = response['is_sufficient'] ?? true;
      final String nextStepStr = response['next_step'] ?? currentStepKey;
      final dynamic extractedData = response['extracted_data'];

      final updatedResumeData = Map<String, dynamic>.from(state.resumeData);
      
      if (isSufficient && extractedData != null) {
        if (updatedResumeData.containsKey(currentStepKey) && updatedResumeData[currentStepKey] is List) {
          if (extractedData is List) {
             (updatedResumeData[currentStepKey] as List).addAll(extractedData);
          } else {
             (updatedResumeData[currentStepKey] as List).add(extractedData);
          }
        } else {
          updatedResumeData[currentStepKey] = extractedData;
        }
      }

      // Convert nextStepStr back to enum
      ResumeStep nextStep = state.currentStep;
      if (nextStepStr == 'experience') nextStep = ResumeStep.experience;
      else if (nextStepStr == 'education') nextStep = ResumeStep.education;
      else if (nextStepStr == 'skills') nextStep = ResumeStep.skills;
      else if (nextStepStr == 'complete') nextStep = ResumeStep.complete;
      else if (nextStepStr == 'summary') nextStep = ResumeStep.summary;

      state = state.copyWith(
        resumeData: updatedResumeData,
        currentStep: nextStep,
        isTyping: false,
      );

      _addMessage(aiReply, false);
      
      // Save updatedResumeData to backend DB here in the future
      
    } catch (e) {
      state = state.copyWith(isTyping: false);
      _addMessage("Sorry, I encountered an error: $e", false);
    }
  }
}

final chatResumeProvider = NotifierProvider<ChatResumeNotifier, ChatResumeState>(() {
  return ChatResumeNotifier();
});
