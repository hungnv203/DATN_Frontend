import 'package:flutter/material.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/booking_usecases.dart';

enum BookingState { initial, loading, success, error }

class BookingProvider extends ChangeNotifier {
  final GetSeatsUseCase _getSeats;
  final CreateBookingUseCase _createBooking;

  BookingProvider(this._getSeats, this._createBooking);

  BookingState state = BookingState.initial;
  String? errorMessage;

  List<Seat> seats = [];
  List<Seat> selectedSeats = [];
  Booking? currentBooking;

  Future<void> fetchSeats(String showtimeId) async {
    try {
      state = BookingState.loading;
      selectedSeats.clear();
      notifyListeners();

      seats = await _getSeats(showtimeId);

      state = BookingState.success;
      notifyListeners();
    } catch (e) {
      state = BookingState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void toggleSeatSelection(Seat seat) {
    if (!seat.isAvailable) return;
    
    if (selectedSeats.contains(seat)) {
      selectedSeats.remove(seat);
    } else {
      selectedSeats.add(seat);
    }
    notifyListeners();
  }

  double getTotalPrice(double basePrice) {
    return selectedSeats.length * basePrice;
  }

  Future<bool> bookTickets(String showtimeId) async {
    if (selectedSeats.isEmpty) return false;

    try {
      state = BookingState.loading;
      notifyListeners();

      final seatIds = selectedSeats.map((s) => s.id).toList();
      currentBooking = await _createBooking(showtimeId, seatIds);

      state = BookingState.success;
      notifyListeners();
      return true;
    } catch (e) {
      state = BookingState.error;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
