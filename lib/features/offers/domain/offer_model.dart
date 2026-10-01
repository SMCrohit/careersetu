class OfferModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String action;
  final String type;
  final String? city;
  final String? discountCode;
  final String? validUntil;

  OfferModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.action,
    required this.type,
    this.city,
    this.discountCode,
    this.validUntil,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      action: json['action'] as String,
      type: json['type'] as String,
      city: json['city'] as String?,
      discountCode: json['discount_code'] as String?,
      validUntil: json['valid_until'] as String?,
    );
  }
}

class ClaimedOfferModel {
  final String id;
  final String userId;
  final String offerId;
  final OfferModel? offer;

  ClaimedOfferModel({
    required this.id,
    required this.userId,
    required this.offerId,
    this.offer,
  });

  factory ClaimedOfferModel.fromJson(Map<String, dynamic> json) {
    return ClaimedOfferModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      offerId: json['offer_id'] as String,
      offer: json['offer'] != null ? OfferModel.fromJson(json['offer']) : null,
    );
  }
}
