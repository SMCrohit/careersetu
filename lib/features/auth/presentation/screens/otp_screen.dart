import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp(String mobileNumber) async {
    if (_otpController.text.length != 4) {
      CustomToast.showError(context, 'Please enter a 4-digit OTP');
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyOtp(mobileNumber, _otpController.text);
    if (success) {
      CustomToast.showSuccess(context, 'Login Successful!');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else {
      if (!mounted) return;
      final error = ref.read(authProvider).error ?? 'Invalid OTP';
      CustomToast.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We pass the mobile number as argument from Login screen
    final mobileNumber = ModalRoute.of(context)?.settings.arguments as String? ?? '9876543210';
    final authState = ref.watch(authProvider);

    final defaultPinTheme = PinTheme(
      width: 64,
      height: 64,
      textStyle: const TextStyle(fontSize: 24, color: AppColors.primaryText, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderDark),
        borderRadius: BorderRadius.circular(4),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryBrand),
      borderRadius: BorderRadius.circular(4),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your number', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  text: 'We sent a 4-digit code to ',
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: [
                    TextSpan(
                      text: '+91 $mobileNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Pinput(
                  controller: _otpController,
                  length: 4,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (pin) => _verifyOtp(mobileNumber),
                ),
              ),
              const SizedBox(height: 32),
              authState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Verify',
                      onPressed: () => _verifyOtp(mobileNumber),
                    ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () {
                    CustomToast.showSuccess(context, 'OTP Resent!');
                  },
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppColors.primaryBrand,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
