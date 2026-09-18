import '../entities/movie.dart';
import '../entities/movie_discovery.dart';
import '../entities/genre.dart';
import '../repositories/movie_repository.dart';

class GetNowPlayingMoviesUseCase {
  final MovieRepository _repository;

  GetNowPlayingMoviesUseCase(this._repository);

  Future<List<Movie>> call({String? genreId}) {
    return _repository.getNowPlayingMovies(genreId: genreId);
  }
}

class GetUpcomingMoviesUseCase {
  final MovieRepository _repository;

  GetUpcomingMoviesUseCase(this._repository);

  Future<List<Movie>> call({String? genreId}) {
    return _repository.getUpcomingMovies(genreId: genreId);
  }
}

class GetGenresUseCase {
  final MovieRepository _repository;

  GetGenresUseCase(this._repository);

  Future<List<Genre>> call() {
    return _repository.getGenres();
  }
}

class GetMovieDiscoveryUseCase {
  GetMovieDiscoveryUseCase(this._repository);

  final MovieRepository _repository;

  Future<MovieDiscovery> call() {
    return _repository.getDiscovery();
  }
}

class GetMovieDetailsUseCase {
  GetMovieDetailsUseCase(this._repository);

  final MovieRepository _repository;

  Future<Movie> call(String id) {
    return _repository.getMovieDetails(id);
  }
}
