import 'room.dart';

class Cinema {
  final String id;
  final String name;
  final String address;
  final String city;
  final List<Room>? rooms;

  const Cinema({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.rooms,
  });
}
