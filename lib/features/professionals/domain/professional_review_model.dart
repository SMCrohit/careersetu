class ProfessionalReview {
  final String id;
  final String professionalId;
  final String userId;
  final double rating;
  final String? comment;
  final String? userName;

  ProfessionalReview({
    required this.id,
    required this.professionalId,
    required this.userId,
    required this.rating,
    this.comment,
    this.userName,
  });

  factory ProfessionalReview.fromJson(Map<String, dynamic> json) {
    return ProfessionalReview(
      id: json['id']?.toString() ?? '',
      professionalId: json['professional_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'],
      userName: json['user']?['full_name'] ?? json['user']?['mobile_number'] ?? 'Anonymous User',
    );
  }
}
