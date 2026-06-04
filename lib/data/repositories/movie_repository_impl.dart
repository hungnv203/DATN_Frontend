import '../../domain/entities/movie.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_data_source.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;

  MovieRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Movie>> getNowPlayingMovies() async {
    return await remoteDataSource.getNowPlayingMovies();
  }

  @override
  Future<List<Movie>> getUpcomingMovies() async {
    return await remoteDataSource.getUpcomingMovies();
  }

  @override
  Future<Movie> getMovieDetails(String id) async {
    return await remoteDataSource.getMovieDetails(id);
  }
}
