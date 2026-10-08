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

  final _whatsappController = TextEditingController();
  bool _isSameAsWhatsapp = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).updateProfileDetails({
        'full_name': _nameController.text,
        'email': _emailController.text,
        'whatsapp_number': _isSameAsWhatsapp ? (ref.read(authProvider).currentUser?.mobileNumber ?? '') : _whatsappController.text,
      });

      if (success) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Career Setu', style: TextStyle(color: AppColors.primaryBrand, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F1FF), // Slate 100 F1F5F9
              Color(0xFFFFFFFF), // White
            ],
          ),
        ),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Great!', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text('Just a couple of details to set up your account.', style: Theme.of(context).textTheme.bodyLarge),
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
                  const SizedBox(height: 16),
                  
                  CheckboxListTile(
                    title: Text(
                      'Is your WhatsApp number the same as this mobile number (+91 ${authState.currentUser?.mobileNumber ?? ''})?', 
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: _isSameAsWhatsapp,
                    onChanged: (val) {
                      setState(() {
                        _isSameAsWhatsapp = val ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryBrand,
                  ),
                  
                  if (!_isSameAsWhatsapp) ...[
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'WhatsApp Number',
                      hintText: '10-digit number',
                      prefixText: '+91 ',
                      keyboardType: TextInputType.phone,
                      controller: _whatsappController,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (!_isSameAsWhatsapp) {
                          if (v == null || v.isEmpty) return 'Enter WhatsApp number';
                          if (v.length != 10) return 'Must be exactly 10 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  const Text(
                    'By clicking Agree & Join, you agree to the Career Setu User Agreement and Privacy Policy.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  authState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: PrimaryButton(
                            text: 'Continue to Dashboard',
                            width: MediaQuery.of(context).size.width * 0.7,
                            onPressed: _saveProfile,
                          ),
                        ),
                ],
              ),
              ),
            ),
          ),
        ),
      );
  }
}
