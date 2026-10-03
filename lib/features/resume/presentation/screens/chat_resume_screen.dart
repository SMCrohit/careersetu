import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';

import '../providers/resume_provider.dart';
import 'resume_preview_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class ChatResumeScreen extends ConsumerStatefulWidget {
  const ChatResumeScreen({super.key});

  @override
  ConsumerState<ChatResumeScreen> createState() => _ChatResumeScreenState();
}

class _ChatResumeScreenState extends ConsumerState<ChatResumeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).currentUser;
      ref.read(chatResumeProvider.notifier).initializeChat(user);
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatResumeProvider.notifier).sendMessage(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatResumeProvider);
    final messages = chatState.messages;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Resume Builder'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: AppColors.primaryBrand),
            tooltip: 'Upload Resume',
            onPressed: () {
              final user = ref.read(authProvider).currentUser;
              if (user != null) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ResumeBottomSheet(user: user),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primaryBrand),
            tooltip: 'Generate Resume',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumePreviewScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (chatState.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (chatState.isTyping && index == 0) {
                  return _buildTypingIndicator();
                }
                final msgIndex = chatState.isTyping ? index - 1 : index;
                final msg = messages[messages.length - 1 - msgIndex];
                return _buildMessage(msg.text, msg.isUser);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryBrand),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isUser) {
    if (text == 'UPLOAD_RESUME_BUTTON') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            onPressed: () {
              final user = ref.read(authProvider).currentUser;
              if (user != null) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ResumeBottomSheet(user: user),
                );
              }
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBrand,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );
    }
    
    if (text == 'GENERATE_RESUME_BUTTON') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumePreviewScreen()));
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate your Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBrand,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBrand : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? AppColors.white : AppColors.primaryText,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBrand),
            ),
            SizedBox(width: 8),
            Text('AI is typing...', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
