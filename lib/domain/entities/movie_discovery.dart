import 'movie.dart';

class MovieDiscovery {
  const MovieDiscovery({
    required this.featured,
    required this.trending,
    required this.topRated,
    required this.bestSelling,
    required this.newReleases,
    required this.upcoming,
  });

  final List<Movie> featured;
  final List<Movie> trending;
  final List<Movie> topRated;
  final List<Movie> bestSelling;
  final List<Movie> newReleases;
  final List<Movie> upcoming;
}
