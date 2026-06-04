import '../../domain/entities/showtime.dart';
import 'cinema_model.dart';

class ShowtimeModel extends Showtime {
  const ShowtimeModel({
    required super.id,
    required super.movieId,
    required super.roomId,
    required super.startTime,
    required super.endTime,
    required super.basePrice,
    required super.status,
    super.room,
  });

  factory ShowtimeModel.fromJson(Map<String, dynamic> json) {
    return ShowtimeModel(
      id: json['id'] ?? '',
      movieId: json['movieId'] ?? '',
      roomId: json['roomId'] ?? '',
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : DateTime.now(),
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      room: json['room'] != null ? RoomModel.fromJson(json['room']) : null,
    );
  }
}
