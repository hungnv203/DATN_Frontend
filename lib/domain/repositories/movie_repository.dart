import '../entities/movie.dart';
import '../entities/movie_discovery.dart';

abstract class MovieRepository {
  Future<List<Movie>> getNowPlayingMovies();
  Future<List<Movie>> getUpcomingMovies();
  Future<Movie> getMovieDetails(String id);
  Future<MovieDiscovery> getDiscovery();
}
