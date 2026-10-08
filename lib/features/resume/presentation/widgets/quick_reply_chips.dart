import 'package:flutter/material.dart';
import '../../domain/chat_message.dart';
import 'resume_ui.dart';

/// Tappable quick replies shown under the latest assistant message.
class QuickReplyChips extends StatelessWidget {
  final List<ChatOption> options;
  final ValueChanged<ChatOption> onTap;

  const QuickReplyChips({super.key, required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final primary = o.kind == 'preview' || o.kind == 'upload';
        return Material(
          color: primary ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onTap(o),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: primary ? ResumeUi.accentGradient : null,
                borderRadius: BorderRadius.circular(20),
                border: primary ? null : Border.all(color: ResumeUi.accent.withOpacity(0.6)),
              ),
              child: Text(
                o.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : const Color(0xFF0369A1),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
