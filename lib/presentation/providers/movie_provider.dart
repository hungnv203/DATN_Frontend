import 'package:flutter/material.dart';
import '../../domain/entities/movie.dart';
import '../../domain/usecases/movie_usecases.dart';

enum MovieState { initial, loading, success, error }

class MovieProvider extends ChangeNotifier {
  final GetNowPlayingMoviesUseCase _getNowPlaying;
  final GetUpcomingMoviesUseCase _getUpcoming;

  MovieProvider(this._getNowPlaying, this._getUpcoming);

  MovieState state = MovieState.initial;
  String? errorMessage;
  
  List<Movie> nowPlayingMovies = [];
  List<Movie> upcomingMovies = [];

  Future<void> fetchMovies() async {
    try {
      state = MovieState.loading;
      notifyListeners();

      final results = await Future.wait([
        _getNowPlaying(),
        _getUpcoming(),
      ]);

      nowPlayingMovies = results[0];
      upcomingMovies = results[1];

      state = MovieState.success;
      notifyListeners();
    } catch (e) {
      state = MovieState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
