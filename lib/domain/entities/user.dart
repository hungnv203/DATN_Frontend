class User {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? avatarUrl;
  final int loyaltyPoints;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.avatarUrl,
    required this.loyaltyPoints,
  });
}
