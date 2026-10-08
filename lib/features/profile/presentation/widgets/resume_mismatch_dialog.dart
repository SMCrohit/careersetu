import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/resume_analysis.dart';

enum ResumeMismatchAction { uploadAnother, editInfo }

/// Shown when the details on an uploaded resume don't match the user's profile.
class ResumeMismatchDialog extends StatelessWidget {
  final ResumeAnalysis analysis;

  const ResumeMismatchDialog({super.key, required this.analysis});

  static Future<ResumeMismatchAction?> show(BuildContext context, ResumeAnalysis analysis) {
    return showDialog<ResumeMismatchAction>(
      context: context,
      useRootNavigator: true,
      builder: (_) => ResumeMismatchDialog(analysis: analysis),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mismatches = analysis.mismatches;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: const Icon(Icons.person_search, color: Color(0xFFD97706), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'It seems this is not your resume',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              const SizedBox(height: 8),
              Text(
                mismatches.isEmpty
                    ? "We couldn't find your name, email or phone number on this resume."
                    : "The details on this resume don't match your profile. Please upload your own resume, or update your info if it has changed.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              if (mismatches.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    children: mismatches.entries.map((e) => _buildRow(e.key, e.value)).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, ResumeMismatchAction.uploadAnother),
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text('Upload correct resume', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, ResumeMismatchAction.editInfo),
                  icon: const Icon(Icons.edit_note, color: AppColors.primaryBrand),
                  label: const Text('Edit my info', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBrand)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryBrand),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String key, IdentityCheck check) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ResumeAnalysis.checkLabels[key] ?? key,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          const SizedBox(height: 4),
          _buildValue('Profile', check.profileValue),
          _buildValue('Resume', check.resumeValue, highlight: true),
        ],
      ),
    );
  }

  Widget _buildValue(String label, String? value, {bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
        ),
        Expanded(
          child: Text(
            value ?? '-',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.error : AppColors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}
