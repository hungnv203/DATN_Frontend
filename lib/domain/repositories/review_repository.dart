import '../entities/review.dart';

abstract class ReviewRepository {
  Future<List<MovieReview>> getReviews(String movieId);
  Future<RatingSummary> getRatingSummary(String movieId);
  Future<MovieReview> submitReview(String movieId, int rating, String comment);
}
