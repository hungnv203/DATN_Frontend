import 'seat.dart';
import 'showtime.dart';

class Booking {
  final String id;
  final String userId;
  final String showtimeId;
  final String status;
  final double subtotal;
  final double discountAmount;
  final double pointDiscountAmount;
  final int usedPoints;
  final String? promotionCode;
  final double totalPrice;
  final DateTime? expiredAt;
  final List<Seat>? seats;
  final Showtime? showtime;

  const Booking({
    required this.id,
    required this.userId,
    required this.showtimeId,
    required this.status,
    this.subtotal = 0,
    this.discountAmount = 0,
    this.pointDiscountAmount = 0,
    this.usedPoints = 0,
    this.promotionCode,
    required this.totalPrice,
    this.expiredAt,
    this.seats,
    this.showtime,
  });
}
