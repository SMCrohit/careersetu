import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';

import '../providers/resume_provider.dart';
import 'resume_preview_screen.dart';

class ChatResumeScreen extends ConsumerStatefulWidget {
  const ChatResumeScreen({super.key});

  @override
  ConsumerState<ChatResumeScreen> createState() => _ChatResumeScreenState();
}

class _ChatResumeScreenState extends ConsumerState<ChatResumeScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatResumeProvider.notifier).sendMessage(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatResumeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Resume Builder'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumePreviewScreen()));
            },
            child: const Text('Generate PDF', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
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
}
