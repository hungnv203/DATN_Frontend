import '../entities/movie.dart';
import '../entities/movie_discovery.dart';
import '../entities/genre.dart';

abstract class MovieRepository {
  Future<List<Movie>> getNowPlayingMovies({String? genreId});
  Future<List<Movie>> getUpcomingMovies({String? genreId});
  Future<Movie> getMovieDetails(String id);
  Future<MovieDiscovery> getDiscovery();
  Future<List<Genre>> getGenres();
}
