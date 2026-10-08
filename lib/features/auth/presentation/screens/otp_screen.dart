import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../providers/auth_provider.dart';
import '../../domain/user_model.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 30;
      _canResend = false;
    });
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            _canResend = true;
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _verifyOtp(String mobileNumber, {bool isSignup = false, User? signupData}) async {
    if (_otpController.text.length != 6) {
      CustomToast.showError(context, 'Please enter a 6-digit OTP');
      return;
    }

    bool success;
    if (isSignup && signupData != null) {
      success = await ref.read(authProvider.notifier).verifySignupOtp(signupData, _otpController.text);
    } else {
      success = await ref.read(authProvider.notifier).verifyOtp(mobileNumber, _otpController.text);
    }

    if (success) {
      CustomToast.showSuccess(context, isSignup ? 'OTP Verified!' : 'Login Successful!');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/auth_wrapper', (route) => false);
    } else {
      if (!mounted) return;
      final error = ref.read(authProvider).error ?? 'Invalid OTP';
      CustomToast.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String mobileNumber = '9876543210';
    bool isSignup = false;
    User? signupData;

    if (args is String) {
      mobileNumber = args;
    } else if (args is Map<String, dynamic>) {
      mobileNumber = args['mobileNumber'] as String;
      isSignup = args['isSignup'] as bool? ?? false;
      signupData = args['signupData'] as User?;
    }

    final authState = ref.watch(authProvider);

    final defaultPinTheme = PinTheme(
      width: 64,
      height: 64,
      textStyle: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.cyanAccent),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
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
                const SizedBox(height: 32),
                Text(
                  'Verify your number',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 26, 
                    color: Colors.white,
                    shadows: [const Shadow(color: Colors.white54, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'We sent a 6-digit code to\n',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  children: [
                    TextSpan(
                      text: '+91 $mobileNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (pin) => _verifyOtp(mobileNumber, isSignup: isSignup, signupData: signupData),
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
                        onPressed: () => _verifyOtp(mobileNumber, isSignup: isSignup, signupData: signupData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: const Text(
                          'Verify',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _canResend ? () {
                    startTimer();
                    CustomToast.showSuccess(context, 'OTP Resent!');
                    // Call backend resend OTP logic here if needed
                  } : null,
                  child: Text(
                    _canResend ? 'Resend Code' : 'Resend Code in 00:${_start.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _canResend ? Colors.cyanAccent : Colors.white54,
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
    ),);
  }
}
