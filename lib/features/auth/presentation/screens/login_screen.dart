import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/user_model.dart';
import '../providers/auth_provider.dart';
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      bool success = await ref.read(authProvider.notifier).requestOtp(_mobileController.text);
      bool isSignup = false;

      if (!success) {
        final error = ref.read(authProvider).error;
        if (error == "User not found. Please sign up.") {
          // Send signup OTP instead
          final tempUser = User(
            mobileNumber: _mobileController.text,
            fullName: '',
            email: '',
            city: '',
            goal: '',
          );
          success = await ref.read(authProvider.notifier).requestSignupOtp(tempUser);
          isSignup = true;
        }
      }

      if (success) {
        CustomToast.showSuccess(context, 'OTP sent successfully!');
        if (!mounted) return;
        Navigator.pushNamed(context, '/otp', arguments: {
          'mobileNumber': _mobileController.text,
          'isSignup': isSignup,
          'signupData': isSignup ? User(
            mobileNumber: _mobileController.text,
            fullName: '',
            email: '',
            city: '',
            goal: '',
          ) : null,
        });
      } else {
        if (!mounted) return;
        final error = ref.read(authProvider).error ?? 'Unknown error';
        CustomToast.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A8A),
              Color(0xFF06b6d4),
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
                  const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Career Setu',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 15)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Welcome to Career Setu!',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 26, 
                    color: Colors.white,
                    shadows: [const Shadow(color: Colors.white54, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s get started. Enter your mobile number.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '9876543210',
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('+91 | ', style: TextStyle(color: Colors.white70, fontSize: 18)),
                          ],
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter mobile number';
                      if (value.length != 10) return 'Mobile number must be exactly 10 digits';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                authState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                    : Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0ea5e9), Color(0xFF3b82f6)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text(
                            'Get OTP',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
