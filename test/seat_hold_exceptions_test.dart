import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/core/error/seat_hold_exceptions.dart';

void main() {
  group('SeatHold exceptions', () {
    test('SeatHoldConflict carries message and optional errorCode', () {
      const exception = SeatHoldConflict('Seats unavailable',
          errorCode: 'SEAT_NOT_AVAILABLE');
      expect(exception.message, 'Seats unavailable');
      expect(exception.errorCode, 'SEAT_NOT_AVAILABLE');
    });

    test('SeatHoldConflict works without errorCode', () {
      const exception = SeatHoldConflict('Conflict');
      expect(exception.message, 'Conflict');
      expect(exception.errorCode, isNull);
    });

    test('SeatHoldShowtimeNotBookable carries message', () {
      const exception = SeatHoldShowtimeNotBookable('Showtime started');
      expect(exception.message, 'Showtime started');
    });

    test('SeatHoldLimitExceeded carries message', () {
      const exception = SeatHoldLimitExceeded('Max 8 seats');
      expect(exception.message, 'Max 8 seats');
    });

    test('SeatHoldAlreadyBooked carries message', () {
      const exception = SeatHoldAlreadyBooked('Already booked');
      expect(exception.message, 'Already booked');
    });

    test('SeatHoldBookingAlreadyPending carries message', () {
      const exception = SeatHoldBookingAlreadyPending('Pending booking exists');
      expect(exception.message, 'Pending booking exists');
    });

    test('SeatHoldRateLimited carries message', () {
      const exception = SeatHoldRateLimited('Too many requests');
      expect(exception.message, 'Too many requests');
    });

    test('SeatHoldUnavailable carries message', () {
      const exception = SeatHoldUnavailable('Not found');
      expect(exception.message, 'Not found');
    });

    test('SeatHoldAuthenticationRequired is const', () {
      const exception = SeatHoldAuthenticationRequired();
      expect(exception, isA<SeatHoldAuthenticationRequired>());
    });

    test('SeatHoldTransportFailure carries message', () {
      const exception = SeatHoldTransportFailure('Network error');
      expect(exception.message, 'Network error');
    });
  });
}
