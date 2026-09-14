class OfferModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String action;
  final String type;

  OfferModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.action,
    required this.type,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      action: json['action'] as String,
      type: json['type'] as String,
    );
  }
}
