import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

// Fake JSON Database in memory
String fakeDbJson = '''
{
  "users": [
    {
      "mobileNumber": "9876543210",
      "fullName": "Rahul Sharma",
      "email": "rahul.sharma@email.com",
      "city": "Bengaluru",
      "goal": "software_developer"
    }
  ]
}
''';

class AuthRepository {
  List<User> _users = [];

  AuthRepository() {
    _loadFakeDb();
  }

  void _loadFakeDb() {
    final Map<String, dynamic> data = jsonDecode(fakeDbJson);
    final List<dynamic> usersData = data['users'];
    _users = usersData.map((e) => User.fromJson(e)).toList();
  }

  Future<bool> requestOtp(String mobileNumber) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    // For demo: Only allow 9876543210 or recently signed up users.
    return _users.any((u) => u.mobileNumber == mobileNumber);
  }

  Future<User?> verifyOtp(String mobileNumber, String otp) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // For demo: Hardcoded OTP 4321
    if (otp == "4321") {
      try {
        return _users.firstWhere((u) => u.mobileNumber == mobileNumber);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> signup(User user) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // If exists, replace
    _users.removeWhere((u) => u.mobileNumber == user.mobileNumber);
    _users.add(user);
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());
