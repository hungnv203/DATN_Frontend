import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<MovieReview>> getReviews(String movieId) {
    return remoteDataSource.getReviews(movieId);
  }

  @override
  Future<RatingSummary> getRatingSummary(String movieId) {
    return remoteDataSource.getRatingSummary(movieId);
  }

  @override
  Future<MovieReview> submitReview(String movieId, int rating, String comment) {
    return remoteDataSource.submitReview(movieId, rating, comment);
  }
}
