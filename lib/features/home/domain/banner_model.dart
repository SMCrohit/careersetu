class BannerModel {
  final String id;
  final String imageUrl;
  final String linkUrl;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.linkUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url'] ?? '',
      linkUrl: json['link_url'] ?? '',
    );
  }
}
