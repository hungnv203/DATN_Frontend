import 'package:dio/dio.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<List<MovieReviewModel>> getReviews(String movieId);
  Future<RatingSummaryModel> getRatingSummary(String movieId);
  Future<MovieReviewModel> submitReview(
    String movieId,
    int rating,
    String comment,
  );
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final DioClient client;

  ReviewRemoteDataSourceImpl(this.client);

  @override
  Future<List<MovieReviewModel>> getReviews(String movieId) async {
    try {
      final response = await client.get('movies/$movieId/reviews');
      final List<dynamic> data = response.data;
      return data.map((json) => MovieReviewModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<RatingSummaryModel> getRatingSummary(String movieId) async {
    try {
      final response = await client.get('movies/$movieId/rating-summary');
      return RatingSummaryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }

  @override
  Future<MovieReviewModel> submitReview(
    String movieId,
    int rating,
    String comment,
  ) async {
    try {
      final response = await client.post(
        'movies/$movieId/reviews',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
      return MovieReviewModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }
}
