import 'seat.dart';

class SeatStateSnapshot {
  final int version;
  final List<Seat> seats;
  const SeatStateSnapshot(this.version, this.seats);
}

class SeatStateChange {
  final String seatId;
  final String status;
  final DateTime? expiresAtUtc;
  final String? holdGroupId;
  const SeatStateChange({required this.seatId, required this.status, this.expiresAtUtc, this.holdGroupId});
}

class SeatStateEvent {
  final String eventId;
  final String showtimeId;
  final int version;
  final List<SeatStateChange> changes;
  const SeatStateEvent({required this.eventId, required this.showtimeId, required this.version, required this.changes});
}

enum SeatRealtimeConnectionState { disconnected, connecting, connected, reauthenticationRequired }
