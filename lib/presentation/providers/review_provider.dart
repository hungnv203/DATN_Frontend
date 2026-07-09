import 'package:flutter/material.dart';
import '../../domain/entities/review.dart';
import '../../domain/usecases/review_usecases.dart';

enum ReviewState { initial, loading, success, error }

class ReviewProvider extends ChangeNotifier {
  final GetMovieReviewsUseCase _getReviews;
  final GetRatingSummaryUseCase _getRatingSummary;
  final SubmitReviewUseCase _submitReview;

  ReviewProvider(
    this._getReviews,
    this._getRatingSummary,
    this._submitReview,
  );

  ReviewState state = ReviewState.initial;
  String? errorMessage;
  List<MovieReview> reviews = [];
  RatingSummary? summary;

  Future<void> loadMovieReviews(String movieId) async {
    try {
      state = ReviewState.loading;
      notifyListeners();

      reviews = await _getReviews(movieId);
      summary = await _getRatingSummary(movieId);

      state = ReviewState.success;
      notifyListeners();
    } catch (e) {
      state = ReviewState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitReview(
    String movieId,
    int rating,
    String comment,
  ) async {
    try {
      await _submitReview(movieId, rating, comment);
      await loadMovieReviews(movieId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
