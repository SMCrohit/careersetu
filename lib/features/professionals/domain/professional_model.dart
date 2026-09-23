class Professional {
  final String id;
  final String name;
  final String profession;
  final String specialty;
  final String clinic;
  final int experienceYears;
  final double rating;
  final double defaultRating;
  final int reviews;
  final int consultationFee;
  final String? imageUrl;
  final String? description;

  Professional({
    required this.id,
    required this.name,
    required this.profession,
    required this.specialty,
    required this.clinic,
    required this.experienceYears,
    required this.rating,
    required this.defaultRating,
    required this.reviews,
    required this.consultationFee,
    this.imageUrl,
    this.description,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    int expYears = 0;
    if (json['experience'] != null) {
      if (json['experience'] is int) {
        expYears = json['experience'];
      } else if (json['experience'] is String) {
        final match = RegExp(r'\d+').firstMatch(json['experience']);
        if (match != null) {
          expYears = int.tryParse(match.group(0) ?? '0') ?? 0;
        }
      }
    } else {
      expYears = json['experienceYears'] ?? 0;
    }

    return Professional(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profession: json['profession'] ?? 'Professional',
      specialty: json['specialty'] ?? '',
      clinic: json['clinic'] ?? '',
      experienceYears: expYears,
      rating: (json['rating'] ?? json['default_rating'] ?? 4.5).toDouble(),
      defaultRating: (json['default_rating'] ?? 4.5).toDouble(),
      reviews: json['reviews'] ?? 10,
      consultationFee: (json['consultation_fee'] ?? json['consultationFee'] ?? 0).toInt(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      description: json['description'],
    );
  }
}
