import 'package:flutter/material.dart';

/// Colours and decorations shared by the resume builder screens, taken from the Home page.
class ResumeUi {
  /// Home page background.
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3F1FF), Color(0xFFFFFFFF)],
  );

  /// Home hero cards.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF06b6d4)],
  );

  /// Bottom navigation's active button.
  static const accentGradient = LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF3b82f6)]);

  static const accent = Color(0xFF0ea5e9);
  static const ink = Color(0xFF0F172A);
  static const softBlue = Color(0xFFF3F8FF);

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cardShadow,
      );
}

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
