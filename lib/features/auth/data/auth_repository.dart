import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../domain/user_model.dart';
import '../../jobs/data/jobs_repository.dart'; // to get apiClientProvider

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<bool> requestOtp(String mobileNumber) async {
    try {
      await _apiClient.post('/auth/request-otp', data: {'mobile_number': mobileNumber});
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return false; // User not found, needs signup
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String mobileNumber, String otp) async {
    try {
      final response = await _apiClient.post('/auth/verify-otp', data: {
        'mobile_number': mobileNumber,
        'otp': otp,
      });
      return response.data; // Expected {access_token, token_type, user}
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> firebaseLogin(String idToken) async {
    try {
      final response = await _apiClient.post('/auth/firebase-login', data: {
        'id_token': idToken,
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> firebaseSignup(String idToken, User user) async {
    try {
      final response = await _apiClient.post('/auth/firebase-signup', data: {
        'id_token': idToken,
        'user_details': user.toJson(),
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> signup(User user) async {
    try {
      final response = await _apiClient.post('/auth/signup', data: user.toJson());
      return response.data; // Expected {access_token, token_type, user}
    } catch (e) {
      return null;
    }
  }

  Future<User?> updateProfileImage(String base64Image) async {
    try {
      final response = await _apiClient.put('/users/profile', data: {
        'profile_image_url': base64Image
      });
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<User?> updateProfileDetails(
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _apiClient.put(
        '/users/profile',
        data: data,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      return null;
    } catch (e) {
      return null;
    }
  }
}

final authRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

