class Seat {
  final String id;
  final String roomId;
  final String row;
  final int number;
  final String type;
  final bool isAvailable;
  final String status;
  final bool heldByCurrentUser;
  final DateTime? expiresAtUtc;

  const Seat({
    required this.id,
    required this.roomId,
    required this.row,
    required this.number,
    required this.type,
    this.isAvailable = true,
    this.status = 'Available',
    this.heldByCurrentUser = false,
    this.expiresAtUtc,
  });

  String get label => '$row$number';

  Seat copyWith({String? status, bool? heldByCurrentUser, DateTime? expiresAtUtc}) => Seat(
        id: id,
        roomId: roomId,
        row: row,
        number: number,
        type: type,
        isAvailable: (status ?? this.status) == 'Available',
        status: status ?? this.status,
        heldByCurrentUser: heldByCurrentUser ?? this.heldByCurrentUser,
        expiresAtUtc: expiresAtUtc,
      );
}
