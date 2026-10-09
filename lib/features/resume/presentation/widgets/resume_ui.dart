import 'package:flutter/material.dart';
import '../../../../core/widgets/app_ui.dart';

export '../../../../core/widgets/app_ui.dart';

/// The resume builder's name for the shared Home tokens.
typedef ResumeUi = AppUi;

/// Renders text with simple `*bold*` markers, as sent by the assistant.
class RichChatText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const RichChatText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++)
            TextSpan(text: parts[i], style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null),
        ],
      ),
      style: style,
    );
  }
}
