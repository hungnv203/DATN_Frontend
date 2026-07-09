import '../entities/review.dart';
import '../repositories/review_repository.dart';

class GetMovieReviewsUseCase {
  final ReviewRepository _repository;

  GetMovieReviewsUseCase(this._repository);

  Future<List<MovieReview>> call(String movieId) {
    return _repository.getReviews(movieId);
  }
}

class GetRatingSummaryUseCase {
  final ReviewRepository _repository;

  GetRatingSummaryUseCase(this._repository);

  Future<RatingSummary> call(String movieId) {
    return _repository.getRatingSummary(movieId);
  }
}

class SubmitReviewUseCase {
  final ReviewRepository _repository;

  SubmitReviewUseCase(this._repository);

  Future<MovieReview> call(String movieId, int rating, String comment) {
    return _repository.submitReview(movieId, rating, comment);
  }
}
