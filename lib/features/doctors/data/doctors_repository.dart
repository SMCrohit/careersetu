import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/doctor_model.dart';

class DoctorsRepository {
  Future<List<Doctor>> fetchDoctors({int page = 1, int limit = 10, String query = ''}) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final String response = await rootBundle.loadString('assets/data/mock_doctors.json');
    final List<dynamic> data = json.decode(response);
    
    List<Doctor> allDoctors = data.map((json) => Doctor.fromJson(json)).toList();

    // Filter by query
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      allDoctors = allDoctors.where((d) => 
        d.name.toLowerCase().contains(q) || 
        d.specialty.toLowerCase().contains(q) ||
        d.clinic.toLowerCase().contains(q)
      ).toList();
    }

    // Pagination
    final startIndex = (page - 1) * limit;
    if (startIndex >= allDoctors.length) {
      return [];
    }

    final endIndex = (startIndex + limit) > allDoctors.length ? allDoctors.length : (startIndex + limit);
    return allDoctors.sublist(startIndex, endIndex);
  }
}

final doctorsRepositoryProvider = Provider<DoctorsRepository>((ref) {
  return DoctorsRepository();
});
