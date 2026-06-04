import 'seat.dart';
import 'showtime.dart';

class Booking {
  final String id;
  final String userId;
  final String showtimeId;
  final String status;
  final double totalPrice;
  final DateTime? expiredAt;
  final List<Seat>? seats;
  final Showtime? showtime;

  const Booking({
    required this.id,
    required this.userId,
    required this.showtimeId,
    required this.status,
    required this.totalPrice,
    this.expiredAt,
    this.seats,
    this.showtime,
  });
}
