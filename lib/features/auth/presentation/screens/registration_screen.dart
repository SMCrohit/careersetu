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
  final _mobileController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String && _mobileController.text.isEmpty) {
      _mobileController.text = args;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      final user = User(
        mobileNumber: _mobileController.text,
        fullName: _nameController.text,
        email: '',
        city: '',
        goal: '',
      );
      
      final success = await ref.read(authProvider.notifier).requestSignupOtp(user);
      if (success) {
        if (!mounted) return;
        Navigator.pushNamed(context, '/otp', arguments: {
          'mobileNumber': _mobileController.text,
          'isSignup': true,
          'signupData': user,
        });
      } else {
        if (!mounted) return;
        final error = ref.read(authProvider).error ?? 'Signup failed';
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sign In', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
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
                    label: 'Mobile Number',
                    hintText: '9876543210',
                    prefixText: '+91 ',
                    keyboardType: TextInputType.phone,
                    controller: _mobileController,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v!.length != 10 ? 'Must be 10 digits' : null,
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
                          text: 'Agree & Join',
                          onPressed: _signup,
                        ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
