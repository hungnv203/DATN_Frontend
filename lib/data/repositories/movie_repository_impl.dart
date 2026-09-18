import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_discovery.dart';
import '../../domain/entities/genre.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_data_source.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;

  MovieRepositoryImpl(this.remoteDataSource);

  @override
  Future<MovieDiscovery> getDiscovery() {
    return remoteDataSource.getDiscovery();
  }

  @override
  Future<List<Movie>> getNowPlayingMovies({String? genreId}) async {
    return await remoteDataSource.getNowPlayingMovies(genreId: genreId);
  }

  @override
  Future<List<Movie>> getUpcomingMovies({String? genreId}) async {
    return await remoteDataSource.getUpcomingMovies(genreId: genreId);
  }

  @override
  Future<List<Genre>> getGenres() async {
    return await remoteDataSource.getGenres();
  }

  @override
  Future<Movie> getMovieDetails(String id) async {
    return await remoteDataSource.getMovieDetails(id);
  }
}
