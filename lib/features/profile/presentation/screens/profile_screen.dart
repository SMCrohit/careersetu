import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/salary_bottom_sheet.dart';
import '../widgets/notice_period_bottom_sheet.dart';
import '../widgets/chip_manager_bottom_sheet.dart';
import '../widgets/complex_list_manager_bottom_sheet.dart';
import '../widgets/edit_profile_bottom_sheet.dart';
import '../widgets/edit_name_email_bottom_sheet.dart';
import '../widgets/resume_mismatch_dialog.dart';
import '../widgets/resume_save_confirm_dialog.dart';
import '../../data/resume_analysis_repository.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/custom_buttons.dart';
import 'resume_review_edit_screen.dart';
import '../../../../core/constants/app_colors.dart';
import 'settings_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../jobs/presentation/screens/applied_jobs_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'resume_pdf_viewer_screen.dart';
import 'dart:io';
import '../../../auth/domain/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatDob(String dob) {
    try {
      final parsed = DateTime.parse(dob);
      return DateFormat('dd MMMM yyyy').format(parsed);
    } catch (e) {
      return dob;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user data found.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 320.0,
              pinned: true,
              backgroundColor: const Color(0xFF0F172A),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final length = await image.length();
                              if (length > 5 * 1024 * 1024) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image must be less than 5MB', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
                                }
                                return;
                              }
                              final bytes = await image.readAsBytes();
                              final base64String = base64Encode(bytes);
                              final extension = image.path.split('.').last;
                              final dataUrl = 'data:image/$extension;base64,$base64String';
                              final success = await ref.read(authProvider.notifier).updateProfileImage(dataUrl);
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Profile image updated successfully', style: TextStyle(color: Colors.white)),
                                    backgroundColor: AppColors.success,
                                  ));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Failed to update profile image', style: TextStyle(color: Colors.white)),
                                    backgroundColor: AppColors.error,
                                  ));
                                }
                              }
                            }
                          },
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.5), width: 3),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF0ea5e9).withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                              ],
                              color: const Color(0xFF0F172A),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: CircularProgressIndicator(
                                    value: user.profileCompletionScore / 100.0,
                                    backgroundColor: Colors.transparent,
                                    color: const Color(0xFF0ea5e9),
                                    strokeWidth: 4,
                                  ),
                                ),
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: const BoxDecoration(shape: BoxShape.circle),
                                  child: ClipOval(
                                    child: _buildProfileImage(user.profileImageUrl),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showEditNameEmailBottomSheet(context, user),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.email.isEmpty ? 'Add Email' : user.email,
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit_outlined, size: 16, color: Colors.white.withOpacity(0.8)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0ea5e9).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.5)),
                          ),
                          child: Text(
                            'Profile Completion: ${user.profileCompletionScore}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE3F1FF), Color(0xFFFFFFFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader('BASIC & PERSONAL INFO'),
                      _buildListTile(context, 'Mobile Number', user.mobileNumber.isNotEmpty ? user.mobileNumber : 'Add Mobile Number', Icons.phone, onTap: () => _showEditBottomSheet(context, 'mobile_number', 'Mobile Number', user.mobileNumber)),
                      _buildListTile(context, 'WhatsApp Number', user.whatsappNumber.isNotEmpty ? user.whatsappNumber : 'Add WhatsApp', Icons.chat, onTap: () => _showEditBottomSheet(context, 'whatsapp_number', 'WhatsApp Number', user.whatsappNumber)),
                      _buildListTile(context, 'Email', user.email.isNotEmpty ? user.email : 'Add Email', Icons.email, onTap: () => _showEditBottomSheet(context, 'email', 'Email', user.email)),
                      _buildListTile(context, 'Date of Birth', user.dob?.isNotEmpty == true ? _formatDob(user.dob!) : 'Add Date of Birth', Icons.cake, onTap: () => _showEditBottomSheet(context, 'dob', 'Date of Birth', user.dob ?? '')),
                      _buildListTile(context, 'Gender', user.gender.isNotEmpty ? user.gender : 'Add Gender', Icons.person, onTap: () => _showEditBottomSheet(context, 'gender', 'Gender', user.gender)),
                      _buildListTile(context, 'Marital Status', user.maritalStatus.isNotEmpty ? user.maritalStatus : 'Add Marital Status', Icons.family_restroom, onTap: () => _showEditBottomSheet(context, 'marital_status', 'Marital Status', user.maritalStatus)),
                      _buildListTile(context, 'Location (City, State, Pincode)', [user.city, user.state, user.pincode].where((e) => e.isNotEmpty).join(', ').isNotEmpty ? [user.city, user.state, user.pincode].where((e) => e.isNotEmpty).join(', ') : 'Add Location', Icons.location_city, onTap: () => _showEditBottomSheet(context, 'city', 'Location', user.city)),
                      _buildListTile(context, 'Full Address', user.address.isNotEmpty ? user.address : 'Add Full Address', Icons.home, onTap: () => _showEditBottomSheet(context, 'address', 'Address', user.address)),
                      
                      _buildSectionHeader('PROFESSIONAL OVERVIEW'),
                      _buildListTile(context, 'Career Goal', user.goal.isNotEmpty ? user.goal.toUpperCase() : 'Add Goal', Icons.flag, onTap: () => _showEditBottomSheet(context, 'goal', 'Career Goal', user.goal)),
                      _buildListTile(context, 'Professional Summary', user.summary.isNotEmpty ? user.summary : 'Add Summary', Icons.text_snippet, onTap: () => _showEditBottomSheet(context, 'summary', 'Professional Summary', user.summary)),
                      _buildListTile(context, 'Years of Experience', '${user.yearsOfExperience} Years', Icons.work, onTap: () => _showEditBottomSheet(context, 'years_of_experience', 'Years of Experience', user.yearsOfExperience.toString())),
                      _buildListTile(
                        context, 
                        'Current Salary', 
                        user.currentSalary != null ? '₹ ${NumberFormat('#,##,###').format(user.currentSalary)} / year' : 'Add Current Salary', 
                        Icons.payments_outlined, 
                        onTap: () => _showSalaryBottomSheet(context, ref, 'current_salary', 'Current Salary', user.currentSalary)
                      ),
                      _buildListTile(
                        context, 
                        'Expected Salary', 
                        user.expectedSalary != null ? '₹ ${NumberFormat('#,##,###').format(user.expectedSalary)} / year' : 'Add Expected Salary', 
                        Icons.account_balance_wallet_outlined, 
                        onTap: () => _showSalaryBottomSheet(context, ref, 'expected_salary', 'Expected Salary', user.expectedSalary)
                      ),
                      _buildListTile(
                        context, 
                        'Notice Period', 
                        user.noticePeriodDays != null ? (user.noticePeriodDays! % 30 == 0 && user.noticePeriodDays! >= 30 ? '${user.noticePeriodDays! ~/ 30} Months' : '${user.noticePeriodDays} Days') : 'Add Notice Period', 
                        Icons.event_available_outlined, 
                        onTap: () => _showNoticePeriodBottomSheet(context, ref, 'notice_period_days', 'Notice Period', user.noticePeriodDays)
                      ),

                      _buildSectionHeader('DIGITAL PRESENCE'),
                      _buildListTile(context, 'LinkedIn Profile', user.linkedinUrl.isNotEmpty ? user.linkedinUrl : 'Add LinkedIn', Icons.link, onTap: () => _showEditBottomSheet(context, 'linkedin_url', 'LinkedIn URL', user.linkedinUrl)),
                      _buildListTile(context, 'GitHub Profile', user.githubUrl.isNotEmpty ? user.githubUrl : 'Add GitHub', Icons.code, onTap: () => _showEditBottomSheet(context, 'github_url', 'GitHub URL', user.githubUrl)),
                      _buildListTile(context, 'Portfolio URL', user.portfolioUrl.isNotEmpty ? user.portfolioUrl : 'Add Portfolio', Icons.web, onTap: () => _showEditBottomSheet(context, 'portfolio_url', 'Portfolio URL', user.portfolioUrl)),

                      _buildSectionHeader('SKILLS & LANGUAGES'),
                      _buildListTile(context, 'Skills', user.skills?.isNotEmpty == true ? '${user.skills!.length} Skills Added' : 'Add Skills', Icons.lightbulb, onTap: () => _showChipBottomSheet(context, 'skills', 'Skills', user.skills ?? [])),
                      _buildListTile(context, 'Languages', user.languages?.isNotEmpty == true ? '${user.languages!.length} Languages Added' : 'Add Languages', Icons.language, onTap: () => _showChipBottomSheet(context, 'languages', 'Languages', user.languages ?? [])),

                      _buildSectionHeader('EXPERIENCE & EDUCATION'),
                      _buildListTile(context, 'Work Experience', user.workExperience?.isNotEmpty == true ? '${user.workExperience!.length} Roles Added' : 'Add Work Experience', Icons.business, onTap: () => _showComplexListBottomSheet(context, 'work_experience', 'Work Experience', user.workExperience ?? [])),
                      _buildListTile(context, 'Education History', user.educationHistory?.isNotEmpty == true ? '${user.educationHistory!.length} Degrees Added' : 'Add Education', Icons.school, onTap: () => _showComplexListBottomSheet(context, 'education_history', 'Education', user.educationHistory ?? [])),
                      _buildListTile(context, 'Projects', user.projects?.isNotEmpty == true ? '${user.projects!.length} Projects Added' : 'Add Projects', Icons.integration_instructions, onTap: () => _showComplexListBottomSheet(context, 'projects', 'Projects', user.projects ?? [])),
                      _buildListTile(context, 'Certifications', user.certifications?.isNotEmpty == true ? '${user.certifications!.length} Certifications' : 'Add Certifications', Icons.workspace_premium, onTap: () => _showComplexListBottomSheet(context, 'certifications', 'Certifications', user.certifications ?? [])),
                      _buildListTile(context, 'Achievements', user.achievements?.isNotEmpty == true ? '${user.achievements!.length} Achievements' : 'Add Achievements', Icons.emoji_events, onTap: () => _showComplexListBottomSheet(context, 'achievements', 'Achievements', user.achievements ?? [])),
                      
                      _buildSectionHeader('OTHER DETAILS'),
                      _buildListTile(context, 'Hobbies', user.hobbies?.isNotEmpty == true ? '${user.hobbies!.length} Hobbies Added' : 'Add Hobbies', Icons.sports_esports, onTap: () => _showChipBottomSheet(context, 'hobbies', 'Hobbies', user.hobbies ?? [])),
                      _buildListTile(context, 'How did you hear about us?', user.acquisitionSource.isNotEmpty ? user.acquisitionSource : 'Select Source', Icons.campaign, onTap: () => _showEditBottomSheet(context, 'acquisition_source', 'Acquisition Source', user.acquisitionSource)),

                      _buildSectionHeader('APP & ACCOUNT'),
                      _buildListTile(context, 'My Resume', 'View, edit or download your resume', Icons.description_outlined, onTap: () => _showResumeBottomSheet(context, user)),
                      _buildListTile(context, 'My Appointments', 'View booked professionals', Icons.calendar_today_outlined, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentsScreen()));
                      }),
                      _buildListTile(context, 'Applied Jobs', 'View jobs you applied', Icons.work_history_outlined, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AppliedJobsScreen()));
                      }),
                      _buildListTile(context, 'Settings', 'App preferences and account', Icons.settings_outlined, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      }),
                      const SizedBox(height: 24),
                      // Log Out Option
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            ref.read(authProvider.notifier).logout();
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEE2E2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.logout, color: AppColors.error, size: 22),
                                ),
                                const SizedBox(width: 16),
                                const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _showChipBottomSheet(BuildContext context, String fieldKey, String title, List<dynamic> currentList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChipManagerBottomSheet(title: title, fieldKey: fieldKey, currentList: currentList),
    );
  }

  void _showComplexListBottomSheet(BuildContext context, String fieldKey, String title, List<dynamic> currentList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComplexListManagerBottomSheet(title: title, fieldKey: fieldKey, currentList: currentList),
    );
  }

  void _showSalaryBottomSheet(BuildContext context, WidgetRef ref, String field, String title, int? initialValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalaryBottomSheet(
        field: field,
        title: title,
        initialValue: initialValue,
        onSave: (f, v) => ref.read(authProvider.notifier).updateProfileDetails({f: v}),
      ),
    );
  }

  void _showNoticePeriodBottomSheet(BuildContext context, WidgetRef ref, String field, String title, int? initialValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoticePeriodBottomSheet(
        field: field,
        title: title,
        initialValue: initialValue,
        onSave: (f, v) => ref.read(authProvider.notifier).updateProfileDetails({f: v}),
      ),
    );
  }

  void _showEditBottomSheet(BuildContext context, String fieldKey, String title, String currentValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileBottomSheet(title: title, fieldKey: fieldKey, currentValue: currentValue),
    );
  }

  void _showEditNameEmailBottomSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditNameEmailBottomSheet(user: user),
    );
  }

  void _showResumeBottomSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResumeBottomSheet(user: user),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF0ea5e9), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, color: AppColors.secondaryText, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildProfileImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.person, size: 50, color: AppColors.secondaryText);
    }
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: 100, height: 100);
    } else {
      return Image.network(imageUrl, fit: BoxFit.cover, width: 100, height: 100,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: AppColors.secondaryText));
    }
  }
}

class ResumeBottomSheet extends ConsumerStatefulWidget {
  final User user;

  const ResumeBottomSheet({required this.user});

  @override
  ConsumerState<ResumeBottomSheet> createState() => _ResumeBottomSheetState();
}

class _ResumeBottomSheetState extends ConsumerState<ResumeBottomSheet> {
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _statusText = '';
  CancelToken? _cancelToken;

  void _setProgress(int count, int total) {
    if (total != -1 && mounted) {
      setState(() {
        _uploadProgress = count / total;
      });
    }
  }

  void _uploadResume() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result.isEmpty) return;
      final file = result.first;
      final fileSize = file.path != null ? File(file.path!).lengthSync() : 0;
      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) CustomToast.showError(context, 'Resume must be less than 5MB');
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      final resumeData = {
        'filename': file.name,
        'data': base64Encode(bytes),
      };

      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
        _statusText = 'AI is reading your resume...';
      });
      _cancelToken = CancelToken();

      final analysis = await ref.read(resumeAnalysisRepositoryProvider).analyzeResume(
        file.name,
        resumeData['data']!,
        cancelToken: _cancelToken,
        onSendProgress: _setProgress,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _cancelToken = null;
      });

      if (analysis.isMatch) {
        final choice = await ResumeSaveConfirmDialog.show(context, resumeFilename: file.name);
        if (choice == ResumeSaveChoice.resumeOnly) await _saveResume(resumeData);
        return;
      }

      final action = await ResumeMismatchDialog.show(context, analysis);
      if (!mounted) return;
      if (action == ResumeMismatchAction.uploadAnother) {
        _uploadResume();
      } else if (action == ResumeMismatchAction.editInfo) {
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ResumeReviewEditScreen(user: widget.user, analysis: analysis, resumeData: resumeData),
          ),
        );
        if (saved == true && mounted) Navigator.pop(context);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      _onUploadError('Failed to read resume. Please try again.');
    } on ApiException catch (e) {
      _onUploadError(e.message);
    } catch (e) {
      _onUploadError('Something went wrong. Please try again.');
    }
  }

  void _onUploadError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _cancelToken = null;
    });
    CustomToast.showError(context, message);
  }

  Future<void> _saveResume(Map<String, String> resumeData) async {
    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _statusText = 'Saving...';
    });
    _cancelToken = CancelToken();

    final success = await ref.read(authProvider.notifier).updateProfileDetails(
      {'resume_data': resumeData},
      cancelToken: _cancelToken,
      onSendProgress: _setProgress,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _cancelToken = null;
      });
      if (success) {
        CustomToast.showSuccess(context, 'Resume uploaded successfully');
        Navigator.pop(context);
      } else {
        CustomToast.showError(context, 'Failed to upload resume');
      }
    }
  }

  void _viewResume() async {
    final resumeData = widget.user.resumeData;
    if (resumeData == null || resumeData['data'] == null) return;
    
    setState(() => _isLoading = true);
    try {
      final bytes = base64Decode(resumeData['data']);
      final dir = await getTemporaryDirectory();
      final filename = resumeData['filename'] ?? 'resume.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResumePdfViewerScreen(
              filePath: file.path,
              filename: filename,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open resume', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isLoading) return true;

    final shouldCancel = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: const BoxDecoration(gradient: AppUi.backgroundGradient, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              const Text('Cancel upload?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              const Text('Your resume hasn\'t been saved yet. Nothing will change if you cancel.', style: AppText.subtitle),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: SecondaryButton(text: 'Keep uploading', fontSize: 14, onPressed: () => Navigator.pop(context, false))),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Cancel upload', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (shouldCancel == true) {
      _cancelToken?.cancel();
      return true;
    }
    return false;
  }

  /// Shows upload percentage while the file is being sent, then the current step.
  Widget _buildProgress() {
    final uploading = _uploadProgress > 0 && _uploadProgress < 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppUi.card(),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppUi.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                uploading ? 'Uploading… ${(_uploadProgress * 100).toStringAsFixed(0)}%' : _statusText,
                style: AppText.value.copyWith(fontSize: 13.5),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: uploading ? _uploadProgress : null,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppUi.accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResume = widget.user.resumeData != null;
    final filename = hasResume ? (widget.user.resumeData!['filename'] ?? 'Resume.pdf') : '';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE3F1FF), Color(0xFFFFFFFF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Text('My Resume', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText),
                      onPressed: () async {
                        if (await _onWillPop() && mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasResume) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppUi.card(),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(filename, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.value),
                              const SizedBox(height: 2),
                              const Text('PDF document', style: AppText.label),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading && _statusText.isNotEmpty) ...[
                    _buildProgress(),
                  ] else ...[
                    PrimaryButton(text: 'View resume', onPressed: _isLoading ? null : _viewResume),
                    const SizedBox(height: 12),
                    SecondaryButton(text: 'Replace resume', onPressed: _isLoading ? null : _uploadResume),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppUi.accent.withOpacity(0.5), width: 1.4),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(gradient: AppUi.accentGradient, shape: BoxShape.circle),
                          child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text('No resume uploaded yet', style: AppText.value),
                        const SizedBox(height: 4),
                        const Text('PDF · max 5MB. We\'ll check it matches your profile.', textAlign: TextAlign.center, style: AppText.label),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading) _buildProgress() else PrimaryButton(text: 'Upload resume', onPressed: _uploadResume),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
