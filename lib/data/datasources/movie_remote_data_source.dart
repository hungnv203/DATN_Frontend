import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/movie_model.dart';

abstract class MovieRemoteDataSource {
  Future<List<MovieModel>> getNowPlayingMovies();
  Future<List<MovieModel>> getUpcomingMovies();
  Future<MovieModel> getMovieDetails(String id);
}

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final DioClient client;

  MovieRemoteDataSourceImpl(this.client);

  @override
  Future<List<MovieModel>> getNowPlayingMovies() async {
    try {
      final response = await client.get(ApiConstants.movies);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final movies = data.map((json) => MovieModel.fromJson(json)).toList();
        // Return movies released before or today
        return movies.where((m) => m.releaseDate.isBefore(DateTime.now().add(const Duration(days: 1)))).toList();
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
        // Return movies released in the future
        return movies.where((m) => m.releaseDate.isAfter(DateTime.now())).toList();
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
