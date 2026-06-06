import '../../domain/entities/seat.dart';
import '../../domain/entities/booking.dart';
import 'showtime_model.dart';

class SeatModel extends Seat {
  const SeatModel({
    required super.id,
    required super.roomId,
    required super.row,
    required super.number,
    required super.type,
    super.isAvailable,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['seatId'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      row: json['rowLabel'] ?? json['row'] ?? '',
      number: json['seatNumber'] ?? json['number'] ?? 0,
      type: json['type'] ?? '',
      isAvailable: json['status'] == 'Available' || json['isAvailable'] == true,
    );
  }
}

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.showtimeId,
    required super.status,
    required super.totalPrice,
    super.expiredAt,
    super.seats,
    super.showtime,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      showtimeId: json['showtimeId'] ?? '',
      status: json['status'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      expiredAt: json['expiredAt'] != null ? DateTime.parse(json['expiredAt']) : null,
      seats: json['seats'] != null 
        ? (json['seats'] as List).map((e) => SeatModel.fromJson(e)).toList() 
        : null,
      showtime: json['showtime'] != null ? ShowtimeModel.fromJson(json['showtime']) : null,
    );
  }
}
