import '../../domain/entities/movie.dart';

class MovieModel extends Movie {
  const MovieModel({
    required super.id,
    required super.title,
    required super.description,
    required super.duration,
    required super.releaseDate,
    required super.language,
    required super.rating,
    required super.posterUrl,
    required super.status,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      releaseDate: json['releaseDate'] != null ? DateTime.parse(json['releaseDate']) : DateTime.now(),
      language: json['language'] ?? '',
      rating: json['rating'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'releaseDate': releaseDate.toIso8601String(),
      'language': language,
      'rating': rating,
      'posterUrl': posterUrl,
      'status': status,
    };
  }
}
