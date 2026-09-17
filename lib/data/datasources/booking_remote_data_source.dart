import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/booking_model.dart';
import '../models/booking_quote_model.dart';
import '../models/concession_model.dart';
import '../models/loyalty_wallet_model.dart';
import '../models/seat_hold_session_model.dart';
import '../../core/error/seat_hold_exceptions.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> getBookingById(String id);
  Future<String> createPaymentUrl(String bookingId);
  Future<void> handlePaymentReturn(Map<String, String> queryParameters);
  Future<List<SeatModel>> getSeats(String showtimeId);
  Future<SeatHoldSessionModel> createSeatHold(
      String showtimeId, List<String> seatIds);
  Future<SeatHoldSessionModel> getOwnedSeatHold(String holdGroupId);
  Future<SeatHoldSessionModel> replaceSeatHold(
      String holdGroupId, String showtimeId, List<String> seatIds);
  Future<void> releaseSeatHold(String holdGroupId);
  Future<List<ConcessionModel>> getConcessions();
  Future<LoyaltyWalletModel> getLoyaltyWallet();
  Future<BookingQuoteModel> quoteBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
  );
  Future<BookingModel> createBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
    String seatHoldGroupId,
  );
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final DioClient client;

  BookingRemoteDataSourceImpl(this.client);

  @override
  Future<BookingModel> getBookingById(String id) async {
    try {
      final response = await client.get('${ApiConstants.bookings}/$id');
      if (response.statusCode == 200) {
        return BookingModel.fromJson(response.data);
      }
      throw ServerException('Failed to load booking');
    } on DioException catch (error) {
      throw ServerException(error.message ?? 'Unknown error');
    }
  }

  @override
  Future<String> createPaymentUrl(String bookingId) async {
    try {
      final response = await client.post(
        '${ApiConstants.payments}/create-url',
        data: {'bookingId': bookingId},
      );
      final data = response.data;
      final url = data is Map
          ? data['url']?.toString() ?? data['Url']?.toString()
          : data?.toString();
      if (url == null || url.isEmpty) {
        throw ServerException('Payment URL was not returned by the server');
      }
      return url;
    } on DioException catch (error) {
      throw ServerException(error.message ?? 'Unknown error');
    }
  }

  @override
  Future<void> handlePaymentReturn(Map<String, String> queryParameters) async {
    try {
      await client.get(
        '${ApiConstants.payments}/vnpay-return',
        queryParameters: queryParameters,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json, text/html, */*'},
        ),
      );
    } catch (_) {
      // Best-effort callback: server may have already processed or returns non-200,
      // subsequent booking status checks will verify the source of truth.
    }
  }

  @override
  Future<List<SeatModel>> getSeats(String showtimeId) async {
    try {
      final response =
          await client.get('${ApiConstants.showtimes}/$showtimeId/seats');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SeatModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load seats');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<SeatHoldSessionModel> createSeatHold(
          String showtimeId, List<String> seatIds) =>
      _holdRequest(() => client.post('seat-holds',
          data: {'showtimeId': showtimeId, 'seatIds': seatIds}));

  @override
  Future<SeatHoldSessionModel> getOwnedSeatHold(String holdGroupId) =>
      _holdRequest(() => client.get('seat-holds/$holdGroupId'));

  @override
  Future<SeatHoldSessionModel> replaceSeatHold(
          String holdGroupId, String showtimeId, List<String> seatIds) =>
      _holdRequest(() => client.put('seat-holds/$holdGroupId',
          data: {'showtimeId': showtimeId, 'seatIds': seatIds}));

  @override
  Future<void> releaseSeatHold(String holdGroupId) async {
    try {
      final response = await client.delete('seat-holds/$holdGroupId');
      if (response.statusCode != 204) {
        throw ServerException('Seat release failed', response.statusCode);
      }
    } on ServerException catch (error) {
      _throwHoldFailure(error);
    }
  }

  Future<SeatHoldSessionModel> _holdRequest(
      Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return SeatHoldSessionModel.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    } on ServerException catch (error) {
      _throwHoldFailure(error);
    }
  }

  Never _throwHoldFailure(ServerException error) {
    switch (error.statusCode) {
      case 409:
        throw SeatHoldConflict(error.message);
      case 404:
        throw SeatHoldUnavailable(error.message);
      case 401:
      case 403:
        throw const SeatHoldAuthenticationRequired();
      default:
        throw SeatHoldTransportFailure(error.message);
    }
  }

  @override
  Future<List<ConcessionModel>> getConcessions() async {
    try {
      final response = await client.get(ApiConstants.concessions);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => ConcessionModel.fromJson(json))
            .where((item) => item.isActive)
            .toList();
      } else {
        throw ServerException('Failed to load concessions');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<LoyaltyWalletModel> getLoyaltyWallet() async {
    try {
      final response = await client.get(ApiConstants.loyaltyWallet);
      if (response.statusCode == 200) {
        return LoyaltyWalletModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to load loyalty wallet');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<BookingQuoteModel> quoteBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
  ) async {
    try {
      final selectedConcessions = _buildSelectedConcessions(concessions);
      final response = await client.post(
        ApiConstants.bookingQuote,
        data: {
          'showtimeId': showtimeId,
          'seatIds': seatIds,
          'concessions': selectedConcessions,
          'promotionCode': promotionCode,
          'usedPoints': usedPoints,
        },
      );
      if (response.statusCode == 200) {
        return BookingQuoteModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to quote booking');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<BookingModel> createBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
    String seatHoldGroupId,
  ) async {
    try {
      final selectedConcessions = _buildSelectedConcessions(concessions);

      final response = await client.post(
        ApiConstants.bookings,
        data: {
          'showtimeId': showtimeId,
          'status': 'Pending',
          'seatIds': seatIds,
          'seatHoldGroupId': seatHoldGroupId,
          'concessions': selectedConcessions,
          'promotionCode': promotionCode,
          'usedPoints': usedPoints,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BookingModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to create booking');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  List<Map<String, dynamic>> _buildSelectedConcessions(
    Map<String, int> concessions,
  ) {
    return concessions.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
              'concessionId': entry.key,
              'quantity': entry.value,
            })
        .toList();
  }
}
