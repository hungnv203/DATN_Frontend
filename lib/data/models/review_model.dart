import '../../domain/entities/review.dart';

class MovieReviewModel extends MovieReview {
  const MovieReviewModel({
    required super.id,
    required super.movieId,
    required super.userId,
    required super.userName,
    required super.rating,
    required super.comment,
    required super.status,
    required super.createdAt,
  });

  factory MovieReviewModel.fromJson(Map<String, dynamic> json) {
    return MovieReviewModel(
      id: json['id'] ?? '',
      movieId: json['movieId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Movie fan',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class RatingSummaryModel extends RatingSummary {
  const RatingSummaryModel({
    required super.movieId,
    required super.averageRating,
    required super.totalReviews,
  });

  factory RatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return RatingSummaryModel(
      movieId: json['movieId'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }
}
