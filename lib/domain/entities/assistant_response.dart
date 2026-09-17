class AssistantShowtimeSummary {
  const AssistantShowtimeSummary({
    required this.showtimeId,
    required this.cinemaName,
    required this.roomName,
    required this.roomType,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
  });

  final String showtimeId;
  final String cinemaName;
  final String roomName;
  final String roomType;
  final DateTime startTime;
  final DateTime endTime;
  final double basePrice;
}

class AssistantMovieCard {
  const AssistantMovieCard({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.releaseDate,
    required this.language,
    required this.rating,
    required this.posterUrl,
    required this.status,
    required this.genres,
    required this.reason,
    this.upcomingShowtimes = const [],
  });

  final String id;
  final String title;
  final String description;
  final int duration;
  final DateTime releaseDate;
  final String language;
  final String rating;
  final String posterUrl;
  final String status;
  final List<String> genres;
  final String reason;
  final List<AssistantShowtimeSummary> upcomingShowtimes;
}

class AssistantResponse {
  const AssistantResponse({
    required this.kind,
    required this.text,
    required this.language,
    required this.correlationId,
    required this.retryable,
    required this.movies,
    required this.clarificationChoices,
  });

  final String kind;
  final String text;
  final String language;
  final String correlationId;
  final bool retryable;
  final List<AssistantMovieCard> movies;
  final List<String> clarificationChoices;
}

class AssistantChatMessage {
  const AssistantChatMessage({
    required this.role,
    required this.content,
    this.response,
    this.failed = false,
  });

  final String role;
  final String content;
  final AssistantResponse? response;
  final bool failed;
}
