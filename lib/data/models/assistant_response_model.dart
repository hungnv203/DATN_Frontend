import '../../domain/entities/assistant_response.dart';

class AssistantResponseModel extends AssistantResponse {
  const AssistantResponseModel({
    required super.kind,
    required super.text,
    required super.language,
    required super.correlationId,
    required super.retryable,
    required super.movies,
    required super.clarificationChoices,
  });

  factory AssistantResponseModel.fromJson(Map<String, dynamic> json) {
    final moviesJson = json['movies'] as List<dynamic>? ?? const [];
    final choicesJson = json['clarificationChoices'] as List<dynamic>? ?? const [];
    return AssistantResponseModel(
      kind: json['kind'] as String? ?? 'Unavailable',
      text: json['text'] as String? ?? '',
      language: json['language'] as String? ?? 'vi',
      correlationId: json['correlationId'] as String? ?? '',
      retryable: json['retryable'] as bool? ?? false,
      movies: moviesJson
          .map((item) => AssistantMovieCardModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      clarificationChoices: choicesJson.map((item) => item.toString()).toList(),
    );
  }
}

class AssistantMovieCardModel extends AssistantMovieCard {
  const AssistantMovieCardModel({
    required super.id,
    required super.title,
    required super.description,
    required super.duration,
    required super.releaseDate,
    required super.language,
    required super.rating,
    required super.posterUrl,
    required super.status,
    required super.genres,
    required super.reason,
  });

  factory AssistantMovieCardModel.fromJson(Map<String, dynamic> json) {
    final genresJson = json['genres'] as List<dynamic>? ?? const [];
    return AssistantMovieCardModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      releaseDate: DateTime.tryParse(json['releaseDate'] as String? ?? '') ?? DateTime(1970),
      language: json['language'] as String? ?? '',
      rating: json['rating'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ?? '',
      status: json['status'] as String? ?? '',
      genres: genresJson.map((item) => item.toString()).toList(),
      reason: json['reason'] as String? ?? '',
    );
  }
}
