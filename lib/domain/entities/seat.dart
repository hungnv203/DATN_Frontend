class Seat {
  final String id;
  final String roomId;
  final String row;
  final int number;
  final String type;
  final bool isAvailable;

  const Seat({
    required this.id,
    required this.roomId,
    required this.row,
    required this.number,
    required this.type,
    this.isAvailable = true,
  });

  String get label => '$row$number';
}
