class User {
  final String mobileNumber;
  final String fullName;
  final String email;
  final String city;
  final String goal;

  User({
    required this.mobileNumber,
    required this.fullName,
    required this.email,
    required this.city,
    required this.goal,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      mobileNumber: json['mobileNumber'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      goal: json['goal'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobileNumber': mobileNumber,
      'fullName': fullName,
      'email': email,
      'city': city,
      'goal': goal,
    };
  }
}
