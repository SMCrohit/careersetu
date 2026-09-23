import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../providers/auth_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedGoal;

  @override
  void dispose() {
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedGoal != null) {
      final success = await ref.read(authProvider.notifier).updateProfileDetails({
        'email': _emailController.text,
        'city': _cityController.text,
        'goal': _selectedGoal,
      });

      if (success) {
        CustomToast.showSuccess(context, 'Profile completed successfully!');
        // No need to navigate manually, AuthWrapper will handle the state change 
        // since currentUser's city and goal are no longer empty.
      } else {
        final error = ref.read(authProvider).error ?? 'Failed to update profile';
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
        title: const Text('Complete Your Profile'),
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
                Text('Almost there!', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 8),
                Text('Tell us a bit more about yourself to personalize your experience.', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 32),
                
                CustomTextField(
                  label: 'Email Address',
                  hintText: 'Email (Optional)',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
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
                
                const SizedBox(height: 32),
                
                authState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text: 'Submit',
                        onPressed: _submit,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
