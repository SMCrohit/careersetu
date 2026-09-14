class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String clinic;
  final int experienceYears;
  final double rating;
  final int reviews;
  final int consultationFee;
  final String imageUrl;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinic,
    required this.experienceYears,
    required this.rating,
    required this.reviews,
    required this.consultationFee,
    required this.imageUrl,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      clinic: json['clinic'] ?? '',
      experienceYears: json['experienceYears'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: json['reviews'] ?? 0,
      consultationFee: json['consultationFee'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
