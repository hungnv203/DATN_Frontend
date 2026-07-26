import 'package:flutter/material.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_quote.dart';
import '../../domain/entities/concession.dart';
import '../../domain/entities/loyalty_wallet.dart';
import '../../domain/entities/seat.dart';
import '../../domain/usecases/booking_usecases.dart';

enum BookingState { initial, loading, success, error }

class BookingProvider extends ChangeNotifier {
  final GetSeatsUseCase _getSeats;
  final GetConcessionsUseCase _getConcessions;
  final CreateBookingUseCase _createBooking;
  final QuoteBookingUseCase _quoteBooking;
  final GetLoyaltyWalletUseCase _getLoyaltyWallet;
  final GetBookingByIdUseCase _getBookingById;
  final CreatePaymentUrlUseCase _createPaymentUrl;

  BookingProvider(
    this._getSeats,
    this._getConcessions,
    this._createBooking,
    this._quoteBooking,
    this._getLoyaltyWallet,
    this._getBookingById,
    this._createPaymentUrl,
  );

  BookingState state = BookingState.initial;
  String? errorMessage;

  List<Seat> seats = [];
  List<Seat> selectedSeats = [];
  List<Concession> concessions = [];
  Map<String, int> selectedConcessions = {};
  Booking? currentBooking;
  BookingQuote? currentQuote;
  LoyaltyWallet? loyaltyWallet;
  String promotionCode = '';
  int usedPoints = 0;
  int _quoteRequestVersion = 0;

  Future<void> fetchBookingOptions(String showtimeId) async {
    try {
      state = BookingState.loading;
      selectedSeats.clear();
      selectedConcessions.clear();
      notifyListeners();

      seats = await _getSeats(showtimeId);
      concessions = await _getConcessions();
      try {
        loyaltyWallet = await _getLoyaltyWallet();
      } catch (_) {
        loyaltyWallet = null;
      }
      await quoteCurrentSelection(showtimeId);

      state = BookingState.success;
      notifyListeners();
    } catch (e) {
      state = BookingState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchSeats(String showtimeId) async {
    await fetchBookingOptions(showtimeId);
  }

  Future<Booking?> fetchBookingById(String id) async {
    try {
      state = BookingState.loading;
      errorMessage = null;
      notifyListeners();
      currentBooking = await _getBookingById(id);
      state = BookingState.success;
      notifyListeners();
      return currentBooking;
    } catch (error) {
      state = BookingState.error;
      errorMessage = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<String?> createPaymentUrl(String bookingId) async {
    try {
      errorMessage = null;
      return await _createPaymentUrl(bookingId);
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadLoyaltyWallet() async {
    try {
      loyaltyWallet = await _getLoyaltyWallet();
      notifyListeners();
    } catch (e) {
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

  void updatePromotionCode(String code) {
    promotionCode = code.trim();
    notifyListeners();
  }

  void updateUsedPoints(String value) {
    usedPoints = int.tryParse(value) ?? 0;
    if (usedPoints < 0) {
      usedPoints = 0;
    }
    notifyListeners();
  }

  int getConcessionQuantity(String concessionId) {
    return selectedConcessions[concessionId] ?? 0;
  }

  void incrementConcession(Concession concession) {
    selectedConcessions[concession.id] =
        getConcessionQuantity(concession.id) + 1;
    notifyListeners();
  }

  void decrementConcession(Concession concession) {
    final quantity = getConcessionQuantity(concession.id);
    if (quantity <= 0) return;

    if (quantity == 1) {
      selectedConcessions.remove(concession.id);
    } else {
      selectedConcessions[concession.id] = quantity - 1;
    }
    notifyListeners();
  }

  Future<void> quoteCurrentSelection(String showtimeId) async {
    final requestVersion = ++_quoteRequestVersion;
    if (selectedSeats.isEmpty) {
      currentQuote = null;
      notifyListeners();
      return;
    }

    currentQuote = null;
    errorMessage = null;
    notifyListeners();
    try {
      final seatIds = selectedSeats.map((s) => s.id).toList();
      final quote = await _quoteBooking(
        showtimeId,
        seatIds,
        selectedConcessions,
        promotionCode.isEmpty ? null : promotionCode,
        usedPoints,
      );
      if (requestVersion != _quoteRequestVersion) return;
      currentQuote = quote;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (requestVersion != _quoteRequestVersion) return;
      currentQuote = null;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> bookTickets(String showtimeId) async {
    if (selectedSeats.isEmpty || currentQuote == null) return false;

    try {
      state = BookingState.loading;
      notifyListeners();

      final seatIds = selectedSeats.map((s) => s.id).toList();
      currentBooking = await _createBooking(
        showtimeId,
        seatIds,
        selectedConcessions,
        promotionCode.isEmpty ? null : promotionCode,
        usedPoints,
      );

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
