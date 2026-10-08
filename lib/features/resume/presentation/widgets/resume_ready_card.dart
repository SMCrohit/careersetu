import 'package:flutter/material.dart';
import 'resume_ui.dart';

/// Shown when the resume is complete, with a button to open the preview.
class ResumeReadyCard extends StatelessWidget {
  final String text;
  final VoidCallback onPreview;

  const ResumeReadyCard({super.key, required this.text, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ResumeUi.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('Resume ready', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          RichChatText(text, style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text('Preview resume', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ResumeUi.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
