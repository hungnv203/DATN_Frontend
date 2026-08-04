import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/domain/entities/seat.dart';

void main() {
  test('seat realtime merge preserves identity and applies status', () {
    const seat = Seat(
      id: 'seat-1',
      roomId: 'room-1',
      row: 'A',
      number: 1,
      type: 'Standard',
    );

    final held = seat.copyWith(status: 'Held', heldByCurrentUser: true);

    expect(held.id, seat.id);
    expect(held.status, 'Held');
    expect(held.isAvailable, isFalse);
    expect(held.heldByCurrentUser, isTrue);
  });
}
