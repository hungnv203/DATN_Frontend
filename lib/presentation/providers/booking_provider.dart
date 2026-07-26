import 'dart:async';

import 'package:flutter/material.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_quote.dart';
import '../../domain/entities/concession.dart';
import '../../domain/entities/loyalty_wallet.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/seat_hold_session.dart';
import '../../domain/usecases/booking_usecases.dart';

enum BookingState { initial, loading, success, error }

class BookingProvider extends ChangeNotifier {
  final GetSeatsUseCase _getSeats;
  final GetConcessionsUseCase _getConcessions;
  final HoldSeatsUseCase _holdSeats;
  final CreateBookingUseCase _createBooking;
  final QuoteBookingUseCase _quoteBooking;
  final GetLoyaltyWalletUseCase _getLoyaltyWallet;
  final GetBookingByIdUseCase _getBookingById;
  final CreatePaymentUrlUseCase _createPaymentUrl;

  BookingProvider(
    this._getSeats,
    this._getConcessions,
    this._holdSeats,
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
  bool _isUpdatingHold = false;
  SeatHoldSession? _holdSession;
  Duration _holdRemaining = Duration.zero;
  Timer? _holdTimer;

  bool get isUpdatingHold => _isUpdatingHold;
  SeatHoldSession? get holdSession => _holdSession;
  Duration get holdRemaining => _holdRemaining;
  bool get hasActiveHold =>
      _holdSession?.isActive == true && _holdRemaining > Duration.zero;

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

  Future<bool> toggleSeatSelection(Seat seat, String showtimeId) async {
    if (!seat.isAvailable || _isUpdatingHold) return false;

    _isUpdatingHold = true;
    final previousSelectedSeats = List<Seat>.from(selectedSeats);
    if (selectedSeats.contains(seat)) {
      selectedSeats.remove(seat);
    } else {
      selectedSeats.add(seat);
    }
    notifyListeners();

    try {
      final holdSession = await _holdSeats(
        showtimeId,
        selectedSeats.map((selectedSeat) => selectedSeat.id).toList(),
        holdSessionId: _holdSession?.id,
      );
      _applyHoldSession(holdSession, showtimeId);
      errorMessage = null;
      _isUpdatingHold = false;
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      selectedSeats = previousSelectedSeats;
      currentQuote = null;
      try {
        seats = await _getSeats(showtimeId);
      } catch (_) {
        // Keep the original hold error for presentation.
      }
      _isUpdatingHold = false;
      notifyListeners();
      return false;
    }
  }

  void _applyHoldSession(SeatHoldSession session, String showtimeId) {
    _holdTimer?.cancel();
    if (!session.isActive || selectedSeats.isEmpty) {
      _holdSession = null;
      _holdRemaining = Duration.zero;
      return;
    }

    _holdSession = session;
    final expiresAt = session.expiresAt!;
    final serverRemaining = expiresAt.difference(session.serverTime);
    _holdRemaining =
        serverRemaining.isNegative ? Duration.zero : serverRemaining;
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_holdRemaining <= const Duration(seconds: 1)) {
        _holdTimer?.cancel();
        _holdSession = null;
        _holdRemaining = Duration.zero;
        selectedSeats.clear();
        currentQuote = null;
        notifyListeners();
        try {
          seats = await _getSeats(showtimeId);
          notifyListeners();
        } catch (_) {
          // The next screen refresh will reconcile seat availability.
        }
        return;
      }

      _holdRemaining -= const Duration(seconds: 1);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
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

      _holdTimer?.cancel();
      _holdSession = null;
      _holdRemaining = Duration.zero;
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
