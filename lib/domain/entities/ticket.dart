import 'booking.dart';

class Ticket {
  final String id;
  final String bookingId;
  final String qrCodeData;
  final String seatLabel;
  final String status;
  final Booking? booking;
  final String? movieTitle;
  final String? paymentStatus;

  const Ticket({
    required this.id,
    required this.bookingId,
    required this.qrCodeData,
    required this.seatLabel,
    required this.status,
    this.booking,
    this.movieTitle,
    this.paymentStatus,
  });
}
