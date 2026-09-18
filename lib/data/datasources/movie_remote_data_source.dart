import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/movie_model.dart';
import '../models/movie_discovery_model.dart';
import '../models/genre_model.dart';

abstract class MovieRemoteDataSource {
  Future<List<MovieModel>> getNowPlayingMovies({String? genreId});
  Future<List<MovieModel>> getUpcomingMovies({String? genreId});
  Future<MovieModel> getMovieDetails(String id);
  Future<MovieDiscoveryModel> getDiscovery();
  Future<List<GenreModel>> getGenres();
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
  Future<List<MovieModel>> getNowPlayingMovies({String? genreId}) async {
    try {
      final queryParams = genreId != null ? {'genreId': genreId} : null;
      final response = await client.get(ApiConstants.movies, queryParameters: queryParams);
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
  Future<List<MovieModel>> getUpcomingMovies({String? genreId}) async {
    try {
      final queryParams = genreId != null ? {'genreId': genreId} : null;
      final response = await client.get(ApiConstants.movies, queryParameters: queryParams);
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
  Future<List<GenreModel>> getGenres() async {
    try {
      final response = await client.get(ApiConstants.genres);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => GenreModel.fromJson(json)).toList();
      }
      throw ServerException('Failed to load genres');
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
