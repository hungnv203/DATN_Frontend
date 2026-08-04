import '../entities/seat_realtime_state.dart';

abstract class SeatRealtimeRepository {
  Stream<SeatStateEvent> get events;
  Stream<SeatRealtimeConnectionState> get connectionStates;
  Future<SeatStateSnapshot> getSnapshot(String showtimeId);
  Future<void> connect(String showtimeId);
  Future<void> disconnect(String showtimeId);
  Future<void> dispose();
}
