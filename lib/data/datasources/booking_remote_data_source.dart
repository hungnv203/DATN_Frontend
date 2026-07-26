import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/booking_model.dart';
import '../models/booking_quote_model.dart';
import '../models/concession_model.dart';
import '../models/loyalty_wallet_model.dart';
import '../models/seat_hold_session_model.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> getBookingById(String id);
  Future<String> createPaymentUrl(String bookingId);
  Future<List<SeatModel>> getSeats(String showtimeId);
  Future<List<ConcessionModel>> getConcessions();
  Future<LoyaltyWalletModel> getLoyaltyWallet();
  Future<SeatHoldSessionModel> holdSeats(
    String showtimeId,
    List<String> seatIds, {
    String? holdSessionId,
  });
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
  );
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final DioClient client;

  BookingRemoteDataSourceImpl(this.client);

  @override
  Future<SeatHoldSessionModel> holdSeats(
    String showtimeId,
    List<String> seatIds, {
    String? holdSessionId,
  }) async {
    try {
      final response = await client.post(
        '${ApiConstants.bookings}/hold-seats',
        data: {
          'showtimeId': showtimeId,
          'seatIds': seatIds,
          if (holdSessionId != null && holdSessionId.isNotEmpty)
            'holdSessionId': holdSessionId,
        },
      );
      return SeatHoldSessionModel.fromJson(response.data);
    } on DioException catch (error) {
      throw ServerException(error.message ?? 'Unable to hold selected seats');
    }
  }

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
  ) async {
    try {
      final selectedConcessions = _buildSelectedConcessions(concessions);

      final response = await client.post(
        ApiConstants.bookings,
        data: {
          'showtimeId': showtimeId,
          'status': 'Pending',
          'totalPrice': 0.0,
          'userId':
              '00000000-0000-0000-0000-000000000000', // Default empty GUID, backend will assign current user
          'seatIds': seatIds,
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
