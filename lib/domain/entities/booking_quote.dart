class BookingQuote {
  final double seatTotal;
  final double concessionTotal;
  final double subtotal;
  final String? promotionCode;
  final double discountAmount;
  final int usedPoints;
  final double pointDiscountAmount;
  final double totalPrice;
  final String? message;

  const BookingQuote({
    required this.seatTotal,
    required this.concessionTotal,
    required this.subtotal,
    this.promotionCode,
    required this.discountAmount,
    required this.usedPoints,
    required this.pointDiscountAmount,
    required this.totalPrice,
    this.message,
  });
}
