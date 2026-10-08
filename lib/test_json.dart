import 'dart:convert';
import 'package:careersetu/features/auth/domain/user_model.dart';

void main() {
  final jsonString = '''{
    "mobile_number": "1234567890",
    "full_name": "Test User",
    "email": "test@example.com",
    "city": "Mumbai",
    "student_profile": {
      "goal": "{id: ff730516-7fd5-43f0-be90-92a976cb017a, created_datetime: 2026-10-06T18:19:12.214988, is_active: true, deleted_datetime: null, name: Software Engineer}"
    }
  }''';

  final jsonMap = jsonDecode(jsonString);
  final user = User.fromJson(jsonMap);
  print('Goal nested string 2: ' + user.goal);
}
