import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/movie_model.dart';
import '../models/movie_discovery_model.dart';

abstract class MovieRemoteDataSource {
  Future<List<MovieModel>> getNowPlayingMovies();
  Future<List<MovieModel>> getUpcomingMovies();
  Future<MovieModel> getMovieDetails(String id);
  Future<MovieDiscoveryModel> getDiscovery();
}

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final DioClient client;

  MovieRemoteDataSourceImpl(this.client);

  @override
  Future<MovieDiscoveryModel> getDiscovery() async {
    try {
      final response = await client.get('${ApiConstants.movies}/discovery');
      if (response.statusCode == 200) {
        return MovieDiscoveryModel.fromJson(response.data);
      }
      throw ServerException('Failed to load movie discovery');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<List<MovieModel>> getNowPlayingMovies() async {
    try {
      final response = await client.get(ApiConstants.movies);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final movies = data.map((json) => MovieModel.fromJson(json)).toList();
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        return movies.where((m) {
          final status = m.status.trim().toLowerCase();
          final releaseDate = DateTime(
            m.releaseDate.year,
            m.releaseDate.month,
            m.releaseDate.day,
          );
          return status != 'upcoming' &&
              !releaseDate.isAfter(todayDate);
        }).toList();
      } else {
        throw ServerException('Failed to load now playing movies');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<List<MovieModel>> getUpcomingMovies() async {
    try {
      final response = await client.get(ApiConstants.movies);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final movies = data.map((json) => MovieModel.fromJson(json)).toList();
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        return movies.where((m) {
          final status = m.status.trim().toLowerCase();
          final releaseDate = DateTime(
            m.releaseDate.year,
            m.releaseDate.month,
            m.releaseDate.day,
          );
          return status == 'upcoming' || releaseDate.isAfter(todayDate);
        }).toList();
      } else {
        throw ServerException('Failed to load upcoming movies');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<MovieModel> getMovieDetails(String id) async {
    try {
      final response = await client.get('${ApiConstants.movies}/$id');
      if (response.statusCode == 200) {
        return MovieModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to load movie details');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }
}
