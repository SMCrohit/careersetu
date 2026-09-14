import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';

class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? error;

  AuthState({this.currentUser, this.isLoading = false, this.error});

  AuthState copyWith({User? currentUser, bool? isLoading, String? error, bool clearError = false}) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  Future<bool> requestOtp(String mobileNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final exists = await repo.requestOtp(mobileNumber);
      state = state.copyWith(isLoading: false);
      if (!exists) {
        state = state.copyWith(error: "User not found. Please sign up.");
      }
      return exists;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.verifyOtp(mobileNumber, otp);
      if (user != null) {
        state = state.copyWith(isLoading: false, currentUser: user);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: "Invalid OTP");
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
      await repo.signup(user);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
