import 'package:flutter/material.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/genre.dart';
import '../../domain/entities/movie_discovery.dart';
import '../../domain/usecases/movie_usecases.dart';

enum MovieState { initial, loading, success, error }

class MovieProvider extends ChangeNotifier {
  final GetNowPlayingMoviesUseCase _getNowPlaying;
  final GetUpcomingMoviesUseCase _getUpcoming;
  final GetMovieDiscoveryUseCase _getDiscovery;
  final GetMovieDetailsUseCase _getMovieDetails;
  final GetGenresUseCase _getGenres;

  MovieProvider(
    this._getNowPlaying,
    this._getUpcoming,
    this._getDiscovery,
    this._getMovieDetails,
    this._getGenres,
  );

  MovieState state = MovieState.initial;
  String? errorMessage;
  
  List<Movie> nowPlayingMovies = [];
  List<Movie> upcomingMovies = [];
  List<Genre> genres = [];
  String? selectedGenreId;
  MovieDiscovery? discovery;
  Movie? selectedMovie;

  Future<void> fetchMovies({bool refreshGenres = true}) async {
    try {
      state = MovieState.loading;
      notifyListeners();

      final discoveryFuture = _getDiscovery()
          .then<MovieDiscovery?>((value) => value)
          .catchError((_) => null);

      final genresFuture = refreshGenres
          ? _getGenres().then<List<Genre>>((value) => value).catchError((_) => <Genre>[])
          : Future.value(genres);

      final results = await Future.wait<List<Movie>>([
        _getNowPlaying(genreId: selectedGenreId),
        _getUpcoming(genreId: selectedGenreId),
      ]);

      nowPlayingMovies = results[0];
      upcomingMovies = results[1];
      discovery = await discoveryFuture;
      genres = await genresFuture;

      state = MovieState.success;
      notifyListeners();
    } catch (e) {
      state = MovieState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> filterByGenre(String? genreId) async {
    if (selectedGenreId == genreId) return;
    selectedGenreId = genreId;
    notifyListeners();
    await fetchMovies(refreshGenres: false);
  }

  Future<void> fetchMovieDetails(String id) async {
    try {
      state = MovieState.loading;
      errorMessage = null;
      selectedMovie = null;
      notifyListeners();
      selectedMovie = await _getMovieDetails(id);
      state = MovieState.success;
      notifyListeners();
    } catch (error) {
      state = MovieState.error;
      errorMessage = error.toString();
      notifyListeners();
    }
  }
}
