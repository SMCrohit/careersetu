import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'resume_ui.dart';

/// Floating message box with an attach button and a gradient send button.
class ChatInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;
  final VoidCallback onAttach;

  const ChatInputBar({super.key, required this.enabled, required this.onSend, required this.onAttach});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (!widget.enabled || !_hasText) return;
    widget.onSend(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.enabled && _hasText;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE3F1FF)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Upload resume',
            onPressed: widget.enabled ? widget.onAttach : null,
            icon: const Icon(Icons.attach_file_rounded, color: ResumeUi.accent),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 15, color: AppColors.primaryText),
              decoration: const InputDecoration(
                hintText: 'Message your resume assistant…',
                hintStyle: TextStyle(color: AppColors.borderDark, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: canSend ? 1 : 0.4,
            child: GestureDetector(
              onTap: canSend ? _send : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: ResumeUi.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: canSend
                      ? [BoxShadow(color: ResumeUi.accent.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
