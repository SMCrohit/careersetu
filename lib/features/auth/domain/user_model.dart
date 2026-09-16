class User {
  final String? id;
  final String mobileNumber;
  final String fullName;
  final String email;
  final String city;
  final String goal;

  User({
    this.id,
    required this.mobileNumber,
    required this.fullName,
    required this.email,
    required this.city,
    required this.goal,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      mobileNumber: json['mobile_number'] ?? json['mobileNumber'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      goal: json['goal'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mobile_number': mobileNumber,
      'full_name': fullName,
      'email': email,
      'city': city,
      'goal': goal,
    };
  }
}
