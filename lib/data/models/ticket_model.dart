import '../../domain/entities/ticket.dart';
import 'booking_model.dart';

class TicketModel extends Ticket {
  const TicketModel({
    required super.id,
    required super.bookingId,
    required super.qrCodeData,
    required super.movieTitle,
    required super.cinemaName,
    required super.roomName,
    super.startTime,
    required super.seatLabel,
    required super.status,
    required super.paymentStatus,
    required super.price,
    super.booking,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final booking =
        json['booking'] != null ? BookingModel.fromJson(json['booking']) : null;
    final startTimeValue = json['startTime'];

    return TicketModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      qrCodeData: json['qrCode'] ?? json['qrCodeData'] ?? '',
      movieTitle: json['movieTitle'] ?? '',
      cinemaName: json['cinemaName'] ?? '',
      roomName: json['roomName'] ?? '',
      startTime: startTimeValue != null
          ? DateTime.tryParse(startTimeValue)
          : booking?.showtime?.startTime,
      seatLabel: json['seatLabel'] ??
          booking?.seats?.map((seat) => seat.label).join(', ') ??
          '',
      status: json['status'] ?? '',
      paymentStatus:
          json['paymentStatus'] ?? booking?.status ?? json['status'] ?? '',
      price: (json['price'] ?? booking?.totalPrice ?? 0).toDouble(),
      booking: booking,
    );
  }
}
