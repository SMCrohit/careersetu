import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/user_model.dart';
import '../providers/auth_provider.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).updateProfileDetails({
        'full_name': _nameController.text,
        'email': _emailController.text,
      });

      if (success) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/complete_profile', (route) => false);
      } else {
        if (!mounted) return;
        final error = ref.read(authProvider).error ?? 'Profile update failed';
        CustomToast.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Career Setu', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Join Career Setu', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text('Find local jobs and build your career today.', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 32),
                  
                  CustomTextField(
                    label: 'Full Name',
                    hintText: 'First and Last Name',
                    controller: _nameController,
                    validator: (v) => v!.isEmpty ? 'Enter full name' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    label: 'Email Address',
                    hintText: 'e.g. name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter email address';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'By clicking Agree & Join, you agree to the Career Setu User Agreement and Privacy Policy.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  authState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                          text: 'Continue',
                          onPressed: _saveProfile,
                        ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
