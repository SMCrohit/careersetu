import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'token_storage.dart';

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

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kReleaseMode 
            ? 'https://careersetu-smc.vercel.app/api' 
            : (dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api'),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // You can log responses or handle generic success states here if needed
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await TokenStorage.deleteToken();
            // TODO: Trigger a global logout event if needed
          }
          return handler.next(_handleError(e));
        },
      ),
    );
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

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
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
