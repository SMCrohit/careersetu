import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/job_model.dart';

class JobsRepository {
  Future<List<JobModel>> fetchJobs({
    int page = 1, 
    int limit = 10, 
    String query = '', 
    Set<String> filters = const {},
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Load JSON from assets
    final jsonString = await rootBundle.loadString('assets/data/mock_responses.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    
    final List<dynamic> jobsJson = data['jobs'];
    List<JobModel> allJobs = jobsJson.map((e) => JobModel.fromJson(e)).toList();
    
    // Apply search query
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      allJobs = allJobs.where((job) {
        return job.title.toLowerCase().contains(q) || 
               job.company.toLowerCase().contains(q) ||
               job.location.toLowerCase().contains(q);
      }).toList();
    }

    // Apply simple mock filters
    if (filters.isNotEmpty) {
      if (filters.contains('Full-time')) {
        allJobs = allJobs.where((job) => job.type == 'Full-time').toList();
      }
      if (filters.contains('Distance')) {
        // Just sort by shortest distance string length or keep simple mock implementation
        allJobs.sort((a, b) => a.location.compareTo(b.location));
      }
      // Add more generic mock filters here if needed
    }
    
    // Simulate pagination
    final startIndex = (page - 1) * limit;
    if (startIndex >= allJobs.length) {
      return [];
    }
    
    final endIndex = (startIndex + limit) > allJobs.length 
        ? allJobs.length 
        : (startIndex + limit);
        
    return allJobs.sublist(startIndex, endIndex);
  }
}

final jobsRepositoryProvider = Provider((ref) => JobsRepository());
