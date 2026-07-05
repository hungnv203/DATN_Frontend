import 'booking.dart';

class Ticket {
  final String id;
  final String bookingId;
  final String qrCodeData;
  final String movieTitle;
  final String cinemaName;
  final String roomName;
  final DateTime? startTime;
  final String seatLabel;
  final String status;
  final String paymentStatus;
  final double price;
  final Booking? booking;

  const Ticket({
    required this.id,
    required this.bookingId,
    required this.qrCodeData,
    required this.movieTitle,
    required this.cinemaName,
    required this.roomName,
    this.startTime,
    required this.seatLabel,
    required this.status,
    required this.paymentStatus,
    required this.price,
    this.booking,
  });
}
