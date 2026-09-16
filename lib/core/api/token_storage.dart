import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_data';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> saveUser(Map<String, dynamic> userJson) async {
    await _storage.write(key: _userKey, value: jsonEncode(userJson));
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final userStr = await _storage.read(key: _userKey);
    if (userStr != null) {
      try {
        return jsonDecode(userStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
