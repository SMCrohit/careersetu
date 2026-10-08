import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum ResumeSaveChoice { resumeAndInfo, infoOnly, resumeOnly }

/// Asks the user what to save before anything is written to the profile.
class ResumeSaveConfirmDialog extends StatelessWidget {
  final String resumeFilename;

  /// Human-readable labels of the profile fields that will change. Empty when only the resume is offered.
  final List<String> changedFields;

  /// True when the resume's name/email/phone didn't match the profile.
  final bool resumeMismatched;

  const ResumeSaveConfirmDialog({
    super.key,
    required this.resumeFilename,
    this.changedFields = const [],
    this.resumeMismatched = false,
  });

  static Future<ResumeSaveChoice?> show(
    BuildContext context, {
    required String resumeFilename,
    List<String> changedFields = const [],
    bool resumeMismatched = false,
  }) {
    return showDialog<ResumeSaveChoice>(
      context: context,
      useRootNavigator: true,
      builder: (_) => ResumeSaveConfirmDialog(
        resumeFilename: resumeFilename,
        changedFields: changedFields,
        resumeMismatched: resumeMismatched,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInfo = changedFields.isNotEmpty;

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
              const Text('Save to your profile?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 16),
              _buildSummaryTile(Icons.picture_as_pdf, 'Resume', resumeFilename),
              if (hasInfo) ...[
                const SizedBox(height: 10),
                _buildSummaryTile(Icons.person_outline, 'Updated info (${changedFields.length})', changedFields.join(', ')),
              ],
              const SizedBox(height: 24),
              if (hasInfo) ...[
                _buildPrimary(context, 'Save resume & info', ResumeSaveChoice.resumeAndInfo),
                const SizedBox(height: 10),
                _buildOutlined(context, 'Save info only', ResumeSaveChoice.infoOnly),
                const SizedBox(height: 10),
                _buildOutlined(context, 'Save resume only', ResumeSaveChoice.resumeOnly),
                if (resumeMismatched)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "If you save only the resume, its name/email won't match your profile.",
                      style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                    ),
                  ),
              ] else
                _buildPrimary(context, 'Save resume', ResumeSaveChoice.resumeOnly),
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

  Widget _buildSummaryTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBrand, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimary(BuildContext context, String label, ResumeSaveChoice choice) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, choice),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrand,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildOutlined(BuildContext context, String label, ResumeSaveChoice choice) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, choice),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryBrand),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBrand)),
      ),
    );
  }
}
