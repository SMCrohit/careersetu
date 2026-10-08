import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/ai_service.dart';
import '../../domain/chat_message.dart';
import '../../domain/resume_draft.dart';

class ChatResumeState {
  final List<ChatMessage> messages;
  final ResumeDraft draft;
  final String stage;
  final bool isLoading;
  final bool isTyping;

  /// 0..1 while a resume file is being sent, otherwise null.
  final double? uploadProgress;

  ChatResumeState({
    this.messages = const [],
    ResumeDraft? draft,
    this.stage = 'new',
    this.isLoading = false,
    this.isTyping = false,
    this.uploadProgress,
  }) : draft = draft ?? ResumeDraft();

  bool get isBusy => isTyping || uploadProgress != null;

  ChatResumeState copyWith({
    List<ChatMessage>? messages,
    ResumeDraft? draft,
    String? stage,
    bool? isLoading,
    bool? isTyping,
    double? uploadProgress,
    bool clearUpload = false,
  }) {
    return ChatResumeState(
      messages: messages ?? this.messages,
      draft: draft ?? this.draft,
      stage: stage ?? this.stage,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      uploadProgress: clearUpload ? null : (uploadProgress ?? this.uploadProgress),
    );
  }
}

class ChatResumeNotifier extends Notifier<ChatResumeState> {
  bool _initialized = false;

  /// The last request sent, so a failed one can be retried from its chip.
  Future<void> Function()? _lastRequest;

  AIService get _service => ref.read(aiServiceProvider);

  @override
  ChatResumeState build() => ChatResumeState();

  /// Restores the saved conversation, or starts a new one.
  Future<void> init({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;
    state = state.copyWith(isLoading: true);
    try {
      final session = await _service.getSession();
      state = state.copyWith(messages: session.messages, draft: session.draft, stage: session.stage, isLoading: false);
      if (session.messages.isEmpty) await _request(() => _service.chat('init'));
    } catch (e) {
      _initialized = false;
      state = state.copyWith(isLoading: false);
      _addError(e, () => init(force: true));
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isBusy) return;
    _addMessage(ChatMessage(role: 'user', text: trimmed));
    await _request(() => _service.chat('message', text: trimmed));
  }

  Future<void> choose(ChatOption option) async {
    if (state.isBusy) return;
    switch (option.kind) {
      case 'message':
        await send(option.label);
      case 'upload':
        await uploadResume();
      case 'retry':
        _removeLastErrorMessage();
        await _lastRequest?.call();
      case 'choice':
        _addMessage(ChatMessage(role: 'user', text: option.label));
        await _request(() => _service.chat('choice', choice: option.id, text: option.label));
    }
  }

  /// Picks a PDF and sends it for the AI to read. Returns an error message to show, if any.
  Future<String?> uploadResume() async {
    if (state.isBusy) return null;
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result.isEmpty) return null;

    final file = result.first;
    final size = file.path != null ? File(file.path!).lengthSync() : 0;
    if (size > 5 * 1024 * 1024) return 'Resume must be less than 5MB';
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return "Couldn't read that file";
    if (bytes.length > 5 * 1024 * 1024) return 'Resume must be less than 5MB';

    final payload = {'filename': file.name, 'data': base64Encode(bytes)};
    _addMessage(ChatMessage(role: 'user', type: 'file', text: file.name));
    await _request(
      () => _service.chat('upload', file: payload, onSendProgress: (count, total) {
        if (total > 0) state = state.copyWith(uploadProgress: count / total);
      }),
      uploading: true,
    );
    return null;
  }

  /// Saves edits made in the resume editor.
  Future<void> saveDraft(ResumeDraft draft) async {
    final saved = await _service.saveDraft(draft);
    state = state.copyWith(draft: saved);
  }

  /// Clears the conversation and starts over.
  Future<void> reset() async {
    if (state.isBusy) return;
    state = state.copyWith(isLoading: true);
    try {
      await _service.reset();
      state = ChatResumeState();
      _initialized = false;
      await init();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _addError(e, reset);
    }
  }

  Future<void> _request(Future<ResumeChatResult> Function() call, {bool uploading = false}) async {
    Future<void> run() async {
      state = state.copyWith(isTyping: true, uploadProgress: uploading ? 0 : null);
      try {
        final result = await call();
        state = state.copyWith(
          messages: [...state.messages, ...result.messages],
          draft: result.draft,
          stage: result.stage,
          isTyping: false,
          clearUpload: true,
        );
      } catch (e) {
        state = state.copyWith(isTyping: false, clearUpload: true);
        _addError(e, run);
      }
    }

    await run();
  }

  void _addMessage(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void _addError(Object error, Future<void> Function() retry) {
    _lastRequest = retry;
    final reason = error is ApiException ? error.message : 'Something went wrong.';
    _addMessage(ChatMessage(
      role: 'assistant',
      type: 'error',
      text: "Sorry, I couldn't get that through. $reason",
      options: const [ChatOption(id: 'retry', label: 'Try again', kind: 'retry')],
    ));
  }

  void _removeLastErrorMessage() {
    if (state.messages.isNotEmpty && state.messages.last.type == 'error') {
      state = state.copyWith(messages: state.messages.sublist(0, state.messages.length - 1));
    }
  }
}

final chatResumeProvider = NotifierProvider<ChatResumeNotifier, ChatResumeState>(ChatResumeNotifier.new);
