import '../../domain/entities/loyalty_wallet.dart';

class PointTransactionModel extends PointTransaction {
  const PointTransactionModel({
    required super.id,
    required super.userId,
    super.bookingId,
    required super.points,
    required super.type,
    required super.balanceAfter,
    required super.description,
    super.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      bookingId: json['bookingId']?.toString(),
      points: json['points'] ?? 0,
      type: json['type'] ?? '',
      balanceAfter: json['balanceAfter'] ?? 0,
      description: json['description'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class LoyaltyWalletModel extends LoyaltyWallet {
  const LoyaltyWalletModel({
    required super.userId,
    required super.points,
    required super.transactions,
  });

  factory LoyaltyWalletModel.fromJson(Map<String, dynamic> json) {
    final transactionList = json['transactions'] as List<dynamic>? ?? [];
    return LoyaltyWalletModel(
      userId: json['userId'] ?? '',
      points: json['points'] ?? 0,
      transactions: transactionList
          .map((item) => PointTransactionModel.fromJson(item))
          .toList(),
    );
  }
}
