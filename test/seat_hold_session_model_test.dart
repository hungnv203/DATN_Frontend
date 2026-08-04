import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/data/models/seat_hold_session_model.dart';

void main() {
  test('maps authoritative hold session timestamps and exact seats', () {
    final session = SeatHoldSessionModel.fromJson({
      'holdGroupId': 'hold-1',
      'showtimeId': 'showtime-1',
      'seatIds': ['seat-1', 'seat-2'],
      'status': 'Active',
      'expiredAt': '2026-08-02T12:05:00Z',
      'serverTimeUtc': '2026-08-02T12:00:00Z',
    });

    expect(session.holdGroupId, 'hold-1');
    expect(session.seatIds, ['seat-1', 'seat-2']);
    expect(session.isActive, isTrue);
    expect(session.expiresAtUtc.difference(session.serverTimeUtc),
        const Duration(minutes: 5));
  });
}
