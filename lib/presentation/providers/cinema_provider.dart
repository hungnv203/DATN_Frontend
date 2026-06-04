import 'package:flutter/material.dart';
import '../../domain/entities/cinema.dart';
import '../../domain/entities/showtime.dart';
import '../../domain/usecases/cinema_usecases.dart';

enum CinemaState { initial, loading, success, error }

class CinemaProvider extends ChangeNotifier {
  final GetCinemasUseCase _getCinemas;
  final GetShowtimesUseCase _getShowtimes;

  CinemaProvider(this._getCinemas, this._getShowtimes);

  CinemaState state = CinemaState.initial;
  String? errorMessage;

  List<Cinema> cinemas = [];
  List<Showtime> showtimes = [];

  Cinema? selectedCinema;
  DateTime selectedDate = DateTime.now();

  Future<void> fetchCinemas() async {
    try {
      state = CinemaState.loading;
      notifyListeners();

      cinemas = await _getCinemas();
      if (cinemas.isNotEmpty) {
        selectedCinema = cinemas.first;
      }

      state = CinemaState.success;
      notifyListeners();
    } catch (e) {
      state = CinemaState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchShowtimes(String movieId) async {
    try {
      state = CinemaState.loading;
      notifyListeners();

      // Format date to YYYY-MM-DD
      final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      
      showtimes = await _getShowtimes(movieId, dateStr);

      state = CinemaState.success;
      notifyListeners();
    } catch (e) {
      state = CinemaState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void selectCinema(Cinema cinema, String movieId) {
    selectedCinema = cinema;
    notifyListeners();
    fetchShowtimes(movieId);
  }

  void selectDate(DateTime date, String movieId) {
    selectedDate = date;
    notifyListeners();
    fetchShowtimes(movieId);
  }
}
