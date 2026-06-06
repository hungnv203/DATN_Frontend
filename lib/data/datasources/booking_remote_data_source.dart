import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<List<SeatModel>> getSeats(String showtimeId);
  Future<BookingModel> createBooking(String showtimeId, List<String> seatIds);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final DioClient client;

  BookingRemoteDataSourceImpl(this.client);

  @override
  Future<List<SeatModel>> getSeats(String showtimeId) async {
    try {
      final response = await client.get('${ApiConstants.showtimes}/$showtimeId/seats');
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
  Future<BookingModel> createBooking(String showtimeId, List<String> seatIds) async {
    try {
      // 1. Hold seats first
      await client.post(
        '${ApiConstants.bookings}/hold-seats',
        data: {
          'showtimeId': showtimeId,
          'seatIds': seatIds,
        },
      );

      // 2. Create the booking submitting the seatIds
      final response = await client.post(
        ApiConstants.bookings,
        data: {
          'showtimeId': showtimeId,
          'status': 'Pending',
          'totalPrice': 0.0,
          'userId': '00000000-0000-0000-0000-000000000000', // Default empty GUID, backend will assign current user
          'seatIds': seatIds,
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
}
