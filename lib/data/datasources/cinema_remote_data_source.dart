import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/cinema_model.dart';
import '../models/showtime_model.dart';

abstract class CinemaRemoteDataSource {
  Future<List<CinemaModel>> getCinemas();
  Future<List<ShowtimeModel>> getShowtimes(String movieId, String date);
}

class CinemaRemoteDataSourceImpl implements CinemaRemoteDataSource {
  final DioClient client;

  CinemaRemoteDataSourceImpl(this.client);

  @override
  Future<List<CinemaModel>> getCinemas() async {
    try {
      final response = await client.get(ApiConstants.cinemas);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CinemaModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load cinemas');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<List<ShowtimeModel>> getShowtimes(String movieId, String date) async {
    try {
      final response = await client.get(ApiConstants.showtimes);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final allShowtimes = data.map((json) => ShowtimeModel.fromJson(json)).toList();
        // Filter locally by movieId
        return allShowtimes.where((st) => st.movieId == movieId).toList();
      } else {
        throw ServerException('Failed to load showtimes');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }
}
