import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';
import '../../../../core/api/token_storage.dart';

class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? error;
  final bool isInitialCheckDone;

  AuthState({this.currentUser, this.isLoading = false, this.error, this.isInitialCheckDone = false});

  AuthState copyWith({User? currentUser, bool? isLoading, String? error, bool clearError = false, bool? isInitialCheckDone}) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialCheckDone: isInitialCheckDone ?? this.isInitialCheckDone,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Ideally you would do the check asynchronously here or explicitly call initCheck from UI
    return AuthState();
  }

  Future<void> initCheck() async {
    final token = await TokenStorage.getToken();
    final userJson = await TokenStorage.getUser();
    if (token != null && userJson != null) {
      final user = User.fromJson(userJson);
      state = state.copyWith(
          currentUser: user,
          isInitialCheckDone: true);
    } else {
      state = state.copyWith(isInitialCheckDone: true);
    }
  }

  String? _verificationId;
  String? _pendingMobileNumber;

  Future<bool> requestOtp(String mobileNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    Completer<bool> completer = Completer<bool>();
    
    try {
      final repo = ref.read(authRepositoryProvider);
      
      final exists = await repo.requestOtp(mobileNumber);
      if (!exists) {
        state = state.copyWith(isLoading: false, error: "User not found. Please sign up.");
        return false;
      }
      
      final formattedNumber = '+91$mobileNumber';
      _pendingMobileNumber = mobileNumber;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) completer.complete(false);
          state = state.copyWith(isLoading: false, error: e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete(true);
          state = state.copyWith(isLoading: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      return completer.future;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> requestSignupOtp(User user) async {
    state = state.copyWith(isLoading: true, clearError: true);
    Completer<bool> completer = Completer<bool>();
    
    try {
      final repo = ref.read(authRepositoryProvider);
      
      // For signup, ensure user does NOT exist
      final exists = await repo.requestOtp(user.mobileNumber);
      if (exists) {
        state = state.copyWith(isLoading: false, error: "Mobile number already registered. Please log in.");
        return false;
      }
      
      final formattedNumber = '+91${user.mobileNumber}';
      _pendingMobileNumber = user.mobileNumber;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) completer.complete(false);
          state = state.copyWith(isLoading: false, error: e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete(true);
          state = state.copyWith(isLoading: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      return completer.future;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_verificationId == null) throw Exception("Verification ID missing");
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) throw Exception("Failed to get Firebase token");

      final repo = ref.read(authRepositoryProvider);
      final data = await repo.firebaseLogin(idToken);
      
      if (data != null && data['access_token'] != null) {
        await TokenStorage.saveToken(data['access_token']);
        await TokenStorage.saveUser(data['user']);
        final user = User.fromJson(data['user']);
        state = state.copyWith(isLoading: false, currentUser: user);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: "Invalid OTP or Server Error");
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifySignupOtp(User signupUser, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_verificationId == null) throw Exception("Verification ID missing");
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) throw Exception("Failed to get Firebase token");

      final repo = ref.read(authRepositoryProvider);
      final data = await repo.firebaseSignup(idToken, signupUser);
      
      if (data != null && data['access_token'] != null) {
        await TokenStorage.saveToken(data['access_token']);
        await TokenStorage.saveUser(data['user']);
        final user = User.fromJson(data['user']);
        state = state.copyWith(isLoading: false, currentUser: user);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: "Signup Failed");
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signup(User user) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final data = await repo.signup(user);
      if (data != null && data['access_token'] != null) {
         await TokenStorage.saveToken(data['access_token']);
         await TokenStorage.saveUser(data['user']);
         final newUser = User.fromJson(data['user']);
         state = state.copyWith(isLoading: false, currentUser: newUser);
         return true;
      } else {
         state = state.copyWith(isLoading: false, error: "Signup failed");
         return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.deleteToken();
    state = AuthState(isInitialCheckDone: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
