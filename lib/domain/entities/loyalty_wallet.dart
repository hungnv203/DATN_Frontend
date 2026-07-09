class PointTransaction {
  final String id;
  final String userId;
  final String? bookingId;
  final int points;
  final String type;
  final int balanceAfter;
  final String description;
  final DateTime? createdAt;

  const PointTransaction({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.points,
    required this.type,
    required this.balanceAfter,
    required this.description,
    this.createdAt,
  });
}

class LoyaltyWallet {
  final String userId;
  final int points;
  final List<PointTransaction> transactions;

  const LoyaltyWallet({
    required this.userId,
    required this.points,
    required this.transactions,
  });
}
