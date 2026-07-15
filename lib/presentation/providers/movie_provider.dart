import 'package:flutter/material.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_discovery.dart';
import '../../domain/usecases/movie_usecases.dart';

enum MovieState { initial, loading, success, error }

class MovieProvider extends ChangeNotifier {
  final GetNowPlayingMoviesUseCase _getNowPlaying;
  final GetUpcomingMoviesUseCase _getUpcoming;
  final GetMovieDiscoveryUseCase _getDiscovery;

  MovieProvider(this._getNowPlaying, this._getUpcoming, this._getDiscovery);

  MovieState state = MovieState.initial;
  String? errorMessage;
  
  List<Movie> nowPlayingMovies = [];
  List<Movie> upcomingMovies = [];
  MovieDiscovery? discovery;

  Future<void> fetchMovies() async {
    try {
      state = MovieState.loading;
      notifyListeners();

      final discoveryFuture = _getDiscovery()
          .then<MovieDiscovery?>((value) => value)
          .catchError((_) => null);
      final results = await Future.wait<List<Movie>>([
        _getNowPlaying(),
        _getUpcoming(),
      ]);

      nowPlayingMovies = results[0];
      upcomingMovies = results[1];
      discovery = await discoveryFuture;

      state = MovieState.success;
      notifyListeners();
    } catch (e) {
      state = MovieState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
