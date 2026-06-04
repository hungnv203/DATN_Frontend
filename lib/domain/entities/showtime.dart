import 'room.dart';

class Showtime {
  final String id;
  final String movieId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final double basePrice;
  final String status;
  final Room? room;

  const Showtime({
    required this.id,
    required this.movieId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
    required this.status,
    this.room,
  });
}
