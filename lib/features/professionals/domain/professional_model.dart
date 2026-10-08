class Professional {
  final String id;
  final String name;
  final String profession;
  final String specialty;
  final String? qualification;
  final String clinic;
  final int experienceYears;
  final double rating;
  final double defaultRating;
  final int reviews;
  final int consultationFee;
  final String? imageUrl;
  final String? description;
  final List<String> timeSlots;
  final List<String> availableDays;
  final String experienceString;
  final bool isFeatured;
  final List<String> consultationMode;
  final List<String> languagesSpoken;

  Professional({
    required this.id,
    required this.name,
    required this.profession,
    required this.specialty,
    this.qualification,
    required this.clinic,
    required this.experienceYears,
    required this.experienceString,
    required this.rating,
    required this.defaultRating,
    required this.reviews,
    required this.consultationFee,
    this.imageUrl,
    this.description,
    this.timeSlots = const [],
    this.availableDays = const [],
    this.isFeatured = false,
    this.consultationMode = const [],
    this.languagesSpoken = const [],
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    int expYears = json['years_experience_numeric'] ?? 0;

    return Professional(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profession: json['profession'] ?? 'Professional',
      specialty: json['specialty'] ?? '',
      qualification: json['qualification'],
      clinic: json['clinic'] ?? '',
      experienceYears: expYears,
      experienceString: json['experience']?.toString() ?? '$expYears Years',
      rating: (json['rating'] ?? json['default_rating'] ?? 4.5).toDouble(),
      defaultRating: (json['default_rating'] ?? 4.5).toDouble(),
      reviews: json['reviews'] ?? 0,
      consultationFee: (json['consultation_fee'] ?? json['consultationFee'] ?? 0).toInt(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      description: json['description'],
      timeSlots: (json['time_slots'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      availableDays: (json['available_days'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFeatured: json['is_featured'] ?? false,
      consultationMode: (json['consultation_mode'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      languagesSpoken: (json['languages_spoken'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
