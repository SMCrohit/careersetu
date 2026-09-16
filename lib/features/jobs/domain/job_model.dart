class JobModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String type;
  final String level;
  final String postedTime;
  final String applicants;
  final String description;
  final List<String> requirements;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.type,
    required this.level,
    required this.postedTime,
    required this.applicants,
    required this.description,
    required this.requirements,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      location: json['location'] as String,
      salary: json['salary'] as String,
      type: json['type'] as String,
      level: json['level'] as String,
      postedTime: json['posted_time'] as String? ?? json['postedTime'] as String? ?? '',
      applicants: json['applicants'] as String? ?? json['applicants']?.toString() ?? '0',
      description: json['description'] as String,
      requirements: List<String>.from(json['requirements'] ?? []),
    );
  }
}
