import '../../domain/entities/movie_discovery.dart';
import 'movie_model.dart';

class MovieDiscoveryModel extends MovieDiscovery {
  const MovieDiscoveryModel({
    required super.featured,
    required super.trending,
    required super.topRated,
    required super.bestSelling,
    required super.newReleases,
    required super.upcoming,
  });

  factory MovieDiscoveryModel.fromJson(Map<String, dynamic> json) {
    List<MovieModel> parseMovies(String key) {
      final values = json[key] as List<dynamic>? ?? const [];
      return values
          .whereType<Map<String, dynamic>>()
          .map(MovieModel.fromJson)
          .toList();
    }

    return MovieDiscoveryModel(
      featured: parseMovies('featured'),
      trending: parseMovies('trending'),
      topRated: parseMovies('topRated'),
      bestSelling: parseMovies('bestSelling'),
      newReleases: parseMovies('newReleases'),
      upcoming: parseMovies('upcoming'),
    );
  }
}
