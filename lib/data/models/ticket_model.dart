import '../../domain/entities/ticket.dart';
import 'booking_model.dart';

class TicketModel extends Ticket {
  const TicketModel({
    required super.id,
    required super.bookingId,
    required super.qrCodeData,
    required super.seatLabel,
    required super.status,
    super.booking,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      qrCodeData: json['qrCodeData'] ?? '',
      seatLabel: json['seatLabel'] ?? '',
      status: json['status'] ?? '',
      booking: json['booking'] != null ? BookingModel.fromJson(json['booking']) : null,
    );
  }
}
