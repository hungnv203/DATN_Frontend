import '../entities/movie.dart';
import '../entities/movie_discovery.dart';
import '../repositories/movie_repository.dart';

class GetNowPlayingMoviesUseCase {
  final MovieRepository _repository;

  GetNowPlayingMoviesUseCase(this._repository);

  Future<List<Movie>> call() {
    return _repository.getNowPlayingMovies();
  }
}

class GetUpcomingMoviesUseCase {
  final MovieRepository _repository;

  GetUpcomingMoviesUseCase(this._repository);

  Future<List<Movie>> call() {
    return _repository.getUpcomingMovies();
  }
}

class GetMovieDiscoveryUseCase {
  GetMovieDiscoveryUseCase(this._repository);

  final MovieRepository _repository;

  Future<MovieDiscovery> call() {
    return _repository.getDiscovery();
  }
}
