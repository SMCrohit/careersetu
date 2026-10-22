import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'token_storage.dart';
import '../navigation/navigation_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return message;
  }
}

class ApiClient {
  late final Dio _dio;

  static String get baseUrl {
    return kReleaseMode 
        ? 'https://careersetu-smc.vercel.app/api' 
        : (dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.7:8000/api');
  }

  ApiClient() {
    if (kDebugMode) {
      debugPrint('[ApiClient] Using API Base URL: $baseUrl');
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          final is401 = e.response?.statusCode == 401;
          final path = e.requestOptions.path;
          final isAuthEndpoint = path.contains('/auth/verify-otp') ||
              path.contains('/auth/firebase-login') ||
              path.contains('/auth/firebase-signup') ||
              path.contains('/auth/signup') ||
              path.contains('/auth/refresh');

          if (is401 && !isAuthEndpoint) {
            try {
              final newAccessToken = await _attemptTokenRefresh();
              if (newAccessToken != null) {
                final options = e.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                final retryResponse = await _dio.fetch(options);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              // Token refresh failed
            }

            // Both token refresh and fallback failed: full session expiration
            await TokenStorage.deleteToken();
            try {
              await FirebaseAuth.instance.signOut();
            } catch (_) {}
            NavigationService.handleSessionExpired();
          }

          return handler.next(_handleError(e));
        },
      ),
    );
  }

  Future<String?> _attemptTokenRefresh() async {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 1. Try Refresh Token
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final resp = await refreshDio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        if (resp.statusCode == 200 && resp.data != null) {
          final newAccessToken = resp.data['access_token'];
          final newRefreshToken = resp.data['refresh_token'];
          if (newAccessToken != null) {
            await TokenStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );
            if (resp.data['user'] != null) {
              await TokenStorage.saveUser(resp.data['user']);
            }
            return newAccessToken as String;
          }
        }
      }
    } catch (_) {}

    // 2. Fallback: Firebase ID token auto-refresh
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final idToken = await fbUser.getIdToken(true);
        if (idToken != null) {
          final resp = await refreshDio.post(
            '/auth/firebase-login',
            data: {'id_token': idToken},
          );
          if (resp.statusCode == 200 && resp.data != null) {
            final newAccessToken = resp.data['access_token'];
            final newRefreshToken = resp.data['refresh_token'];
            if (newAccessToken != null) {
              await TokenStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );
              if (resp.data['user'] != null) {
                await TokenStorage.saveUser(resp.data['user']);
              }
              return newAccessToken as String;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  DioException _handleError(DioException error) {
    String errorMessage = "Something went wrong. Please try again.";
    
    if (error.type == DioExceptionType.connectionTimeout || 
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage = "Connection timed out. Please check your internet connection.";
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        if (statusCode >= 500) {
          errorMessage = "Server error. We are working on it.";
        } else if (statusCode == 404) {
          errorMessage = "Requested resource not found.";
        } else if (statusCode == 401 || statusCode == 403) {
          errorMessage = "Unauthorized access. Please login again.";
        } else if (statusCode == 400) {
          errorMessage = error.response?.data['detail'] ?? "Invalid request. Please check your input.";
        } else {
           errorMessage = error.response?.data['detail'] ?? "An error occurred ($statusCode).";
        }
      }
    } else if (error.type == DioExceptionType.connectionError) {
       errorMessage = "Failed to connect to the server. Please check your internet connection.";
    }

    return error.copyWith(error: ApiException(errorMessage, statusCode: error.response?.statusCode));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }
}

final apiClientProvider = Provider((ref) => ApiClient());
