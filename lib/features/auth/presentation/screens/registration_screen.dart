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
  final _mobileController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedGoal;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate() && _selectedGoal != null) {
      final user = User(
        mobileNumber: _mobileController.text,
        fullName: _nameController.text,
        email: _emailController.text,
        city: _cityController.text,
        goal: _selectedGoal!,
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
    } else if (_selectedGoal == null) {
      CustomToast.showError(context, 'Please select your career goal');
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
                    label: 'Email Address',
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter valid email' : null,
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
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    label: 'City',
                    hintText: 'e.g. Bengaluru',
                    controller: _cityController,
                    validator: (v) => v!.isEmpty ? 'Enter city' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('I want to become', style: TextStyle(fontSize: 12, color: AppColors.primaryText)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderDark),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select an option', style: TextStyle(color: AppColors.secondaryText)),
                        value: _selectedGoal,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryText),
                        items: const [
                          DropdownMenuItem(value: 'professional', child: Text('Professional')),
                          DropdownMenuItem(value: 'engineer', child: Text('Engineer')),
                          DropdownMenuItem(value: 'ias', child: Text('IAS')),
                          DropdownMenuItem(value: 'ips', child: Text('IPS')),
                          DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                          DropdownMenuItem(value: 'lawyer', child: Text('Lawyer')),
                          DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                          DropdownMenuItem(value: 'software_developer', child: Text('Software Developer')),
                          DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                          DropdownMenuItem(value: 'banker', child: Text('Banker')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGoal = value;
                          });
                        },
                      ),
                    ),
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
