class MovieReview {
  final String id;
  final String movieId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final String status;
  final DateTime createdAt;

  const MovieReview({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.status,
    required this.createdAt,
  });
}

class RatingSummary {
  final String movieId;
  final double averageRating;
  final int totalReviews;

  const RatingSummary({
    required this.movieId,
    required this.averageRating,
    required this.totalReviews,
  });
}
