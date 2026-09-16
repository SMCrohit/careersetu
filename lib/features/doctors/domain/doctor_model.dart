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
    // Backend has `experience: str`, we map it to experienceYears by parsing if needed or defaulting to 0
    int expYears = 0;
    if (json['experience'] != null) {
      if (json['experience'] is int) expYears = json['experience'];
      else if (json['experience'] is String) expYears = int.tryParse(json['experience'].split(' ').first) ?? 0;
    } else {
      expYears = json['experienceYears'] ?? 0;
    }

    return Doctor(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      clinic: json['clinic'] ?? '',
      experienceYears: expYears,
      rating: (json['rating'] ?? 4.5).toDouble(),
      reviews: json['reviews'] ?? 10,
      consultationFee: (json['consultation_fee'] ?? json['consultationFee'] ?? 0).toInt(),
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150', // Backend missing image URL for now
    );
  }
}
