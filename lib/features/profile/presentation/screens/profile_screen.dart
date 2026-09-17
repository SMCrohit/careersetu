import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../jobs/presentation/screens/applied_jobs_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../../../auth/data/auth_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'resume_pdf_viewer_screen.dart';
import 'dart:io';
import '../../../auth/domain/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: AppColors.primaryText)),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: user == null
          ? const Center(child: Text('No user data found.'))
            : Column(
                children: [
                  // Top Section (Default Background)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              final base64String = base64Encode(bytes);
                              final extension = image.path.split('.').last;
                              final dataUrl = 'data:image/$extension;base64,$base64String';
                              
                              ref.read(authProvider.notifier).updateProfileImage(dataUrl);
                            }
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 4),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                              ],
                              color: AppColors.backgroundLight,
                            ),
                            child: ClipOval(
                              child: _buildProfileImage(user.profileImageUrl),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.email,
                              style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryBrand),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bottom Section (Solid White Background)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(0, 24, 0, 24 + MediaQuery.of(context).padding.bottom),
                          child: Column(
                            children: [
                              _buildListTile(context, 'Mobile Number', user.mobileNumber, Icons.phone, onTap: () => _showEditBottomSheet(context, 'mobile_number', 'Mobile Number', user.mobileNumber)),
                              _buildDivider(),
                              _buildListTile(context, 'City', user.city, Icons.location_city, onTap: () => _showEditBottomSheet(context, 'city', 'City', user.city)),
                              _buildDivider(),
                              _buildListTile(context, 'Career Goal', user.goal.toUpperCase(), Icons.flag, onTap: () => _showEditBottomSheet(context, 'goal', 'Career Goal', user.goal)),
                              _buildDivider(),
                              _buildListTile(context, 'My Resume', 'View, edit or download your resume', Icons.description_outlined, onTap: () => _showResumeBottomSheet(context, user)),
                              _buildDivider(),
                              _buildListTile(context, 'My Appointments', 'View booked professionals', Icons.calendar_today_outlined, onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentsScreen()));
                              }),
                              _buildDivider(),
                              _buildListTile(context, 'Applied Jobs', 'View jobs you applied', Icons.work_history_outlined, onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AppliedJobsScreen()));
                              }),
                              _buildDivider(),
                              _buildListTile(context, 'Settings', 'App preferences and account', Icons.settings_outlined, onTap: () {}),
                              _buildDivider(),
                              
                              // Log Out Option
                              InkWell(
                                onTap: () {
                                  ref.read(authProvider.notifier).logout();
                                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: AppColors.error, size: 28),
                                      SizedBox(width: 16),
                                      Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  void _showEditBottomSheet(BuildContext context, String fieldKey, String title, String currentValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileBottomSheet(title: title, fieldKey: fieldKey, currentValue: currentValue),
    );
  }

  void _showResumeBottomSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResumeBottomSheet(user: user),
    );
  }

  Widget _buildListTile(BuildContext context, String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBrand, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.primaryText)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.backgroundLight,
      indent: 68, // Aligns divider with text, skips icon
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

class _EditProfileBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String fieldKey;
  final String currentValue;

  const _EditProfileBottomSheet({
    required this.title,
    required this.fieldKey,
    required this.currentValue,
  });

  @override
  ConsumerState<_EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends ConsumerState<_EditProfileBottomSheet> {
  late TextEditingController _controller;
  late TextEditingController _otpController;
  String? _selectedGoal;
  bool _isLoading = false;
  bool _otpSent = false;
  String _verificationId = '';

  final List<String> _goals = [
    'professional', 'engineer', 'ias', 'ips', 'teacher', 'lawyer', 'nurse', 'software_developer', 'accountant', 'banker', 'other'
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
    _otpController = TextEditingController();
    if (widget.fieldKey == 'goal') {
      _selectedGoal = widget.currentValue.toLowerCase();
      if (!_goals.contains(_selectedGoal)) {
        _selectedGoal = 'other';
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _isLoading = true);
    final value = widget.fieldKey == 'goal' ? _selectedGoal : _controller.text.trim();
    
    if (widget.fieldKey == 'mobile_number') {
      if (!_otpSent) {
        // Step 1: Check if number exists in DB
        final exists = await ref.read(authRepositoryProvider).requestOtp(value!);
        if (exists) {
          setState(() => _isLoading = false);
          Navigator.pop(context); // Close sheet to show snackbar cleanly
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number already in use by another account.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
          return;
        }

        // Step 2: Send Firebase OTP
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: '+91$value',
          verificationCompleted: (PhoneAuthCredential credential) async {},
          verificationFailed: (FirebaseAuthException e) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to new number.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.primaryBrand));
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
        return;
      } else {
        // Step 3: Verify OTP and update Firebase & Backend
        try {
          final credential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: _otpController.text.trim());
          await FirebaseAuth.instance.currentUser!.updatePhoneNumber(credential);
          await FirebaseAuth.instance.currentUser!.getIdToken(true); // refresh token
          
          final success = await ref.read(authProvider.notifier).updateProfileDetails({widget.fieldKey: value});
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pop(context);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number updated successfully', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update in database', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
            }
          }
        } on FirebaseAuthException catch (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Invalid OTP', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
        } catch (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
        }
        return;
      }
    }

    // For other fields (City, Goal)
    final data = {widget.fieldKey: value};
    final success = await ref.read(authProvider.notifier).updateProfileDetails(data);
    
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context); // Always close the bottom sheet
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Edit ${widget.title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          if (_otpSent) ...[
            Text('Enter the 6-digit OTP sent to ${_controller.text}', style: const TextStyle(color: AppColors.secondaryText)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBrand)),
                filled: true,
                fillColor: AppColors.backgroundLight,
                hintText: 'Enter OTP',
                counterText: "",
              ),
            ),
          ] else if (widget.fieldKey == 'goal') ...[
            DropdownButtonFormField<String>(
              value: _selectedGoal,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBrand)),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
              items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => _selectedGoal = val),
            )
          ] else ...[
            TextFormField(
              controller: _controller,
              keyboardType: widget.fieldKey == 'mobile_number' ? TextInputType.phone : TextInputType.text,
              maxLength: widget.fieldKey == 'mobile_number' ? 10 : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBrand)),
                filled: true,
                fillColor: AppColors.backgroundLight,
                hintText: 'Enter your ${widget.title.toLowerCase()}',
                counterText: "",
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_otpSent ? 'Verify & Save' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBottomSheet extends ConsumerStatefulWidget {
  final User user;

  const _ResumeBottomSheet({required this.user});

  @override
  ConsumerState<_ResumeBottomSheet> createState() => _ResumeBottomSheetState();
}

class _ResumeBottomSheetState extends ConsumerState<_ResumeBottomSheet> {
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  CancelToken? _cancelToken;

  void _uploadResume() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.isNotEmpty) {
        final file = result.first;
        setState(() => _isLoading = true);
        final bytes = await file.readAsBytes();
        
        if (bytes.isNotEmpty) {
          final base64String = base64Encode(bytes);
          final resumeData = {
            'filename': file.name,
            'data': base64String,
          };

          _cancelToken = CancelToken();
          _uploadProgress = 0.0;

          final success = await ref.read(authProvider.notifier).updateProfileDetails(
            {'resume_data': resumeData},
            cancelToken: _cancelToken,
            onSendProgress: (count, total) {
              if (total != -1) {
                setState(() {
                  _uploadProgress = count / total;
                });
              }
            },
          );
          
          if (mounted) {
            setState(() {
              _isLoading = false;
              _cancelToken = null;
            });
            Navigator.pop(context);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resume uploaded successfully', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload resume', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
            }
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Upload?'),
        content: const Text('Are you sure you want to cancel the resume upload?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (shouldCancel == true) {
      _cancelToken?.cancel();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasResume = widget.user.resumeData != null;
    final filename = hasResume ? (widget.user.resumeData!['filename'] ?? 'Resume.pdf') : '';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Resume', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                IconButton(
                  icon: const Icon(Icons.close), 
                  onPressed: () async {
                    if (await _onWillPop()) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (hasResume) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: AppColors.primaryBrand, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(filename, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          const Text('PDF Document', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading && _uploadProgress > 0) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBrand),
                ),
                const SizedBox(height: 8),
                Center(child: Text('Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold))),
                const SizedBox(height: 24),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _viewResume,
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    label: const Text('View Resume', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _uploadResume,
                    icon: const Icon(Icons.edit, color: AppColors.secondaryText),
                    label: const Text('Edit / Replace Resume', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ] else ...[
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.upload_file, size: 64, color: AppColors.borderDark),
                    const SizedBox(height: 16),
                    const Text('No resume uploaded yet', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                    const SizedBox(height: 24),
                    if (_isLoading) ...[
                      LinearProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBrand),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _uploadProgress > 0 ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%' : 'Processing...', 
                        style: const TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _uploadResume,
                          icon: const Icon(Icons.upload, color: Colors.white),
                          label: const Text('Upload Resume (PDF)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrand,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
