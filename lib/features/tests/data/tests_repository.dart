import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/test_model.dart';

class TestsRepository {
  Future<List<TestModel>> fetchAllTests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final jsonString = await rootBundle.loadString('assets/data/mock_responses.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> testsJson = data['tests'];
    return testsJson.map((e) => TestModel.fromJson(e)).toList();
  }

  Future<TestModel> fetchTest(String id) async {
    final allTests = await fetchAllTests();
    return allTests.firstWhere((t) => t.id == id);
  }
}

final testsRepositoryProvider = Provider((ref) => TestsRepository());
