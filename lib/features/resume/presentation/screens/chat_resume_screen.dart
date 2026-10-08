import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/chat_message.dart';
import '../../domain/resume_draft.dart';
import '../providers/resume_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/quick_reply_chips.dart';
import '../widgets/resume_data_card.dart';
import '../widgets/resume_ready_card.dart';
import '../widgets/resume_ui.dart';
import '../widgets/upload_resume_card.dart';
import 'resume_preview_screen.dart';

/// Conversational AI resume builder (Resume tab).
class ChatResumeScreen extends ConsumerStatefulWidget {
  const ChatResumeScreen({super.key});

  @override
  ConsumerState<ChatResumeScreen> createState() => _ChatResumeScreenState();
}

class _ChatResumeScreenState extends ConsumerState<ChatResumeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(chatResumeProvider.notifier).init());
  }

  Future<void> _upload() async {
    final error = await ref.read(chatResumeProvider.notifier).uploadResume();
    if (error != null && mounted) CustomToast.showError(context, error);
  }

  void _openPreview() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumePreviewScreen()));
  }

  void _onOption(ChatOption option) {
    switch (option.kind) {
      case 'upload':
        _upload();
      case 'preview':
        _openPreview();
      default:
        ref.read(chatResumeProvider.notifier).choose(option);
    }
  }

  Future<void> _confirmStartOver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Start over?'),
        content: const Text('This clears the conversation and the resume built so far. Your profile is not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start over', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) ref.read(chatResumeProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatResumeProvider);
    final messages = chat.messages;

    return Container(
      decoration: const BoxDecoration(gradient: ResumeUi.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            children: [
              _assistantAvatar(size: 36),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Resume Builder',
                      style: TextStyle(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(chat.isBusy ? 'typing…' : 'Online',
                      style: TextStyle(color: chat.isBusy ? ResumeUi.accent : AppColors.success, fontSize: 12)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Preview resume',
              onPressed: chat.draft.hasContent ? _openPreview : null,
              icon: const Icon(Icons.visibility_outlined),
              color: AppColors.primaryText,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.primaryText),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'reset') _confirmStartOver();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'reset',
                  child: Row(children: [Icon(Icons.restart_alt, size: 20), SizedBox(width: 10), Text('Start over')]),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: chat.isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: ResumeUi.accent))
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      itemCount: messages.length + (chat.isTyping && chat.uploadProgress == null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (chat.isTyping && chat.uploadProgress == null) {
                          if (index == 0) return const _TypingIndicator();
                          index -= 1;
                        }
                        final i = messages.length - 1 - index;
                        return _buildMessage(messages[i], isLast: i == messages.length - 1, chat: chat);
                      },
                    ),
            ),
            ChatInputBar(
              enabled: !chat.isBusy && !chat.isLoading,
              onSend: (text) => ref.read(chatResumeProvider.notifier).send(text),
              onAttach: _upload,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, {required bool isLast, required ChatResumeState chat}) {
    if (msg.isUser) return _userBubble(msg, uploading: isLast && chat.uploadProgress != null);

    final showOptions = isLast && !chat.isBusy && msg.options.isNotEmpty;
    final options = msg.type == 'ready_card' ? msg.options.where((o) => o.kind != 'preview').toList() : msg.options;

    Widget body;
    switch (msg.type) {
      case 'data_card':
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.text.isNotEmpty) ...[_assistantBubble(msg.text), const SizedBox(height: 8)],
            ResumeDataCard(draft: ResumeDraft.fromJson(msg.data)),
          ],
        );
      case 'upload_card':
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _assistantBubble(msg.text),
            const SizedBox(height: 8),
            UploadResumeCard(onTap: isLast && !chat.isBusy ? _upload : null),
          ],
        );
      case 'ready_card':
        body = ResumeReadyCard(text: msg.text, onPreview: _openPreview);
      case 'error':
        body = _assistantBubble(msg.text, error: true);
      default:
        body = _assistantBubble(msg.text);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _assistantAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  child: body,
                ),
                if (showOptions && options.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  QuickReplyChips(options: options, onTap: _onOption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assistantAvatar({double size = 30}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: ResumeUi.accentGradient, shape: BoxShape.circle),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.5),
    );
  }

  Widget _assistantBubble(String text, {bool error = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: ResumeUi.cardShadow,
      ),
      child: RichChatText(
        text,
        style: TextStyle(fontSize: 14.5, height: 1.45, color: error ? AppColors.error : AppColors.primaryText),
      ),
    );
  }

  Widget _userBubble(ChatMessage msg, {required bool uploading}) {
    final isFile = msg.type == 'file';
    final progress = ref.read(chatResumeProvider).uploadProgress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 48),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: isFile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(msg.text,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (uploading) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 160,
                        child: LinearProgressIndicator(
                          value: progress != null && progress < 1 ? progress : null,
                          minHeight: 3,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(progress != null && progress < 1 ? 'Uploading…' : 'AI is reading your resume…',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ],
                )
              : Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.45)),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 38),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: ResumeUi.cardShadow,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = ((_controller.value * 3) - i).clamp(0.0, 1.0);
                final lift = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 7,
                  height: 7,
                  transform: Matrix4.translationValues(0, -4 * lift, 0),
                  decoration: BoxDecoration(
                    color: ResumeUi.accent.withOpacity(0.4 + 0.6 * lift),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
