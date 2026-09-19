import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    super.avatarUrl,
    required super.loyaltyPoints,
    super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, [String? fallbackRole]) {
    int points = 0;
    if (json['loyaltyPoint'] != null) {
      points = json['loyaltyPoint']['points'] ?? 0;
    } else if (json['loyaltyPoints'] != null) {
      points = json['loyaltyPoints'];
    }

    String? role = json['roleName'] ?? json['role'];
    if (role == null && json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      role = (json['roles'] as List).first.toString();
    }
    role ??= fallbackRole;

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      avatarUrl: json['avatarUrl'],
      loyaltyPoints: points,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'loyaltyPoints': loyaltyPoints,
      'role': role,
    };
  }
}
