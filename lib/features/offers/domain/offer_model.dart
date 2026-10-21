class OfferModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String action;
  final String type;
  final String? city;
  final String? state;
  final String? pincode;
  final String? targetProfessions;
  final String? discountCode;
  final String? validUntil;
  final String? merchantName;
  final String? merchantLogo;
  final String? merchantAddress;
  final String? partnerPhone;
  final String? externalUrl;
  final String redemptionType;
  final String? termsAndConditions;
  final String? targetStream;
  final int minResumeScore;
  final int? totalQuota;
  final int claimedCount;
  final int? availableVouchersCount;

  OfferModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.action,
    required this.type,
    this.city,
    this.state,
    this.pincode,
    this.targetProfessions,
    this.discountCode,
    this.validUntil,
    this.merchantName,
    this.merchantLogo,
    this.merchantAddress,
    this.partnerPhone,
    this.externalUrl,
    this.redemptionType = 'generic_code',
    this.termsAndConditions,
    this.targetStream = 'All',
    this.minResumeScore = 0,
    this.totalQuota,
    this.claimedCount = 0,
    this.availableVouchersCount,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      action: json['action'] as String? ?? 'Claim',
      type: json['type'] as String? ?? 'Gyms & Fitness',
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      targetProfessions: json['target_professions'] as String?,
      discountCode: json['discount_code'] as String?,
      validUntil: json['valid_until'] as String?,
      merchantName: json['merchant_name'] as String?,
      merchantLogo: json['merchant_logo'] as String?,
      merchantAddress: json['merchant_address'] as String?,
      partnerPhone: json['partner_phone'] as String?,
      externalUrl: json['external_url'] as String?,
      redemptionType: json['redemption_type'] as String? ?? 'generic_code',
      termsAndConditions: json['terms_and_conditions'] as String?,
      targetStream: json['target_stream'] as String? ?? 'All',
      minResumeScore: json['min_resume_score'] as int? ?? 0,
      totalQuota: json['total_quota'] as int?,
      claimedCount: json['claimed_count'] as int? ?? 0,
      availableVouchersCount: json['available_vouchers_count'] as int?,
    );
  }
}

class ClaimedOfferModel {
  final String id;
  final String userId;
  final String offerId;
  final String? voucherCode;
  final String status;
  final String? createdDatetime;
  final String? redeemedAt;
  final Map<String, dynamic>? inquiryDetails;
  final OfferModel? offer;

  ClaimedOfferModel({
    required this.id,
    required this.userId,
    required this.offerId,
    this.voucherCode,
    this.status = 'active',
    this.createdDatetime,
    this.redeemedAt,
    this.inquiryDetails,
    this.offer,
  });

  factory ClaimedOfferModel.fromJson(Map<String, dynamic> json) {
    return ClaimedOfferModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      offerId: json['offer_id'] as String,
      voucherCode: json['voucher_code'] as String?,
      status: json['status'] as String? ?? 'active',
      createdDatetime: json['created_datetime'] as String?,
      redeemedAt: json['redeemed_at'] as String?,
      inquiryDetails: json['inquiry_details'] as Map<String, dynamic>?,
      offer: json['offer'] != null ? OfferModel.fromJson(json['offer']) : null,
    );
  }
}
