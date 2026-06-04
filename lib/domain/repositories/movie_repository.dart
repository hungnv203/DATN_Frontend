import '../entities/movie.dart';

abstract class MovieRepository {
  Future<List<Movie>> getNowPlayingMovies();
  Future<List<Movie>> getUpcomingMovies();
  Future<Movie> getMovieDetails(String id);
}
