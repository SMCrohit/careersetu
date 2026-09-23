import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditResumeScreen extends ConsumerStatefulWidget {
  const EditResumeScreen({super.key});

  @override
  ConsumerState<EditResumeScreen> createState() => _EditResumeScreenState();
}

class _EditResumeScreenState extends ConsumerState<EditResumeScreen> {
  late TextEditingController _summaryController;
  late TextEditingController _skillsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    final resumeData = user?.resumeData ?? {};
    
    _summaryController = TextEditingController(text: resumeData['summary'] ?? '');
    _skillsController = TextEditingController(text: resumeData['skills'] ?? '');
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return;

      final updatedResumeData = Map<String, dynamic>.from(user.resumeData ?? {});
      updatedResumeData['summary'] = _summaryController.text;
      updatedResumeData['skills'] = _skillsController.text;

      // In a real app, you would call an API here to update the user profile
      // await ref.read(authProvider.notifier).updateProfile(resumeData: updatedResumeData);
      
      CustomToast.showSuccess(context, 'Resume details saved successfully!');
      Navigator.pop(context);
    } catch (e) {
      CustomToast.showError(context, 'Failed to save details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Resume Details', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Professional Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _summaryController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your professional summary...',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Skills (comma or newline separated)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _skillsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your skills...',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            // Note: Experience and Education forms omitted for brevity but would follow similar patterns
            const SizedBox(height: 32),
            PrimaryButton(
              text: _isLoading ? 'Saving...' : 'Save Changes',
              onPressed: _isLoading ? null : _saveDetails,
            ),
          ],
        ),
      ),
    );
  }
}
