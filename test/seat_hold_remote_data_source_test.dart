import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/core/error/exceptions.dart';
import 'package:movie_booking_app/core/error/seat_hold_exceptions.dart';
import 'package:movie_booking_app/core/network/dio_client.dart';
import 'package:movie_booking_app/data/datasources/booking_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps typed 409 error codes without parsing the message', () async {
    final cases = <String, Type>{
      'SHOWTIME_NOT_BOOKABLE': SeatHoldShowtimeNotBookable,
      'HOLD_SEAT_LIMIT_EXCEEDED': SeatHoldLimitExceeded,
      'HOLD_ALREADY_BOOKED': SeatHoldAlreadyBooked,
      'BOOKING_ALREADY_PENDING': SeatHoldBookingAlreadyPending,
    };

    for (final entry in cases.entries) {
      final source = await _source(ServerException(
        'Localized message without the code',
        409,
        entry.key,
      ));

      await expectLater(
        source.createSeatHold('showtime', const ['seat']),
        throwsA(predicate<Object>((error) => error.runtimeType == entry.value)),
      );
    }
  });

  test('maps a body-less 429 response to rate limited', () async {
    final source = await _source(ServerException('Too many requests', 429));

    await expectLater(
      source.createSeatHold('showtime', const ['seat']),
      throwsA(isA<SeatHoldRateLimited>()),
    );
  });

  test('maps DELETE hold already booked to the typed exception', () async {
    final source = await _source(ServerException(
      'The hold is linked to a booking',
      409,
      'HOLD_ALREADY_BOOKED',
    ));

    await expectLater(
      source.releaseSeatHold('hold-group'),
      throwsA(isA<SeatHoldAlreadyBooked>()),
    );
  });
}

Future<BookingRemoteDataSourceImpl> _source(ServerException error) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return BookingRemoteDataSourceImpl(_ThrowingDioClient(preferences, error));
}

class _ThrowingDioClient extends DioClient {
  final ServerException error;

  _ThrowingDioClient(super.preferences, this.error);

  @override
  Future<Response> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      Future.error(error);

  @override
  Future<Response> delete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      Future.error(error);
}
