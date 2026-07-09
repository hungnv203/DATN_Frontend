import '../../domain/entities/booking_quote.dart';

class BookingQuoteModel extends BookingQuote {
  const BookingQuoteModel({
    required super.seatTotal,
    required super.concessionTotal,
    required super.subtotal,
    super.promotionCode,
    required super.discountAmount,
    required super.usedPoints,
    required super.pointDiscountAmount,
    required super.totalPrice,
    super.message,
  });

  factory BookingQuoteModel.fromJson(Map<String, dynamic> json) {
    return BookingQuoteModel(
      seatTotal: (json['seatTotal'] ?? 0).toDouble(),
      concessionTotal: (json['concessionTotal'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      promotionCode: json['promotionCode']?.toString(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      usedPoints: json['usedPoints'] ?? 0,
      pointDiscountAmount: (json['pointDiscountAmount'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      message: json['message']?.toString(),
    );
  }
}
