class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final bool emailVerified;
  final bool isPremium;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.emailVerified,
    required this.isPremium,
  });

  String get fullName => '$firstName $lastName'.trim().isEmpty ? email : '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      emailVerified: json['email_verified'] ?? false,
      isPremium: json['is_premium'] ?? false,
    );
  }
}
