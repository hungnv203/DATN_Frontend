import '../../domain/entities/cinema.dart';
import '../../domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.cinemaId,
    required super.name,
    required super.totalSeats,
    required super.type,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      cinemaId: json['cinemaId'] ?? '',
      name: json['name'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      type: json['type'] ?? '',
    );
  }
}

class CinemaModel extends Cinema {
  const CinemaModel({
    required super.id,
    required super.name,
    required super.address,
    required super.city,
    super.rooms,
  });

  factory CinemaModel.fromJson(Map<String, dynamic> json) {
    return CinemaModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      rooms: json['rooms'] != null 
        ? (json['rooms'] as List).map((e) => RoomModel.fromJson(e)).toList() 
        : null,
    );
  }
}
