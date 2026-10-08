import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'resume_ui.dart';

/// Upload area shown in the chat. Shows progress while the file is sent and read.
class UploadResumeCard extends StatelessWidget {
  final VoidCallback? onTap;

  /// null when idle; 0..1 while sending; 1 while the AI reads it.
  final double? progress;

  const UploadResumeCard({super.key, this.onTap, this.progress});

  @override
  Widget build(BuildContext context) {
    final busy = progress != null;
    final reading = busy && progress! >= 1;

    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ResumeUi.softBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ResumeUi.accent.withOpacity(0.5), width: 1.4),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(gradient: ResumeUi.accentGradient, shape: BoxShape.circle),
              child: Icon(busy ? Icons.auto_awesome : Icons.upload_file_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              busy ? (reading ? 'Reading your resume…' : 'Uploading… ${(progress! * 100).round()}%') : 'Upload your resume',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
            const SizedBox(height: 4),
            const Text('PDF · max 5MB', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
            if (busy) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: reading ? null : progress,
                  minHeight: 5,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation(ResumeUi.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
