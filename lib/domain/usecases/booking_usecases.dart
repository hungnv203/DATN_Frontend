import '../entities/booking.dart';
import '../entities/booking_quote.dart';
import '../entities/concession.dart';
import '../entities/loyalty_wallet.dart';
import '../entities/seat.dart';
import '../entities/seat_hold_session.dart';
import '../repositories/booking_repository.dart';

class GetSeatsUseCase {
  final BookingRepository _repository;

  GetSeatsUseCase(this._repository);

  Future<List<Seat>> call(String showtimeId) {
    return _repository.getSeats(showtimeId);
  }
}

class CreateSeatHoldUseCase {
  final BookingRepository _repository;
  CreateSeatHoldUseCase(this._repository);
  Future<SeatHoldSession> call(String showtimeId, List<String> seatIds) =>
      _repository.createSeatHold(showtimeId, seatIds);
}

class GetOwnedSeatHoldUseCase {
  final BookingRepository _repository;
  GetOwnedSeatHoldUseCase(this._repository);
  Future<SeatHoldSession> call(String id) => _repository.getOwnedSeatHold(id);
}

class ReplaceSeatHoldUseCase {
  final BookingRepository _repository;
  ReplaceSeatHoldUseCase(this._repository);
  Future<SeatHoldSession> call(
          String id, String showtimeId, List<String> seats) =>
      _repository.replaceSeatHold(id, showtimeId, seats);
}

class ReleaseSeatHoldUseCase {
  final BookingRepository _repository;
  ReleaseSeatHoldUseCase(this._repository);
  Future<void> call(String id) => _repository.releaseSeatHold(id);
}

class GetConcessionsUseCase {
  final BookingRepository _repository;

  GetConcessionsUseCase(this._repository);

  Future<List<Concession>> call() {
    return _repository.getConcessions();
  }
}

class CreateBookingUseCase {
  final BookingRepository _repository;

  CreateBookingUseCase(this._repository);

  Future<Booking> call(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
    String seatHoldGroupId,
  ) {
    return _repository.createBooking(
      showtimeId,
      seatIds,
      concessions,
      promotionCode,
      usedPoints,
      seatHoldGroupId,
    );
  }
}

class GetBookingByIdUseCase {
  GetBookingByIdUseCase(this._repository);

  final BookingRepository _repository;

  Future<Booking> call(String id) {
    return _repository.getBookingById(id);
  }
}

class CreatePaymentUrlUseCase {
  CreatePaymentUrlUseCase(this._repository);

  final BookingRepository _repository;

  Future<String> call(String bookingId) {
    return _repository.createPaymentUrl(bookingId);
  }
}

class HandlePaymentReturnUseCase {
  HandlePaymentReturnUseCase(this._repository);

  final BookingRepository _repository;

  Future<void> call(Map<String, String> queryParameters) {
    return _repository.handlePaymentReturn(queryParameters);
  }
}

class QuoteBookingUseCase {
  final BookingRepository _repository;

  QuoteBookingUseCase(this._repository);

  Future<BookingQuote> call(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
  ) {
    return _repository.quoteBooking(
      showtimeId,
      seatIds,
      concessions,
      promotionCode,
      usedPoints,
    );
  }
}

class GetLoyaltyWalletUseCase {
  final BookingRepository _repository;

  GetLoyaltyWalletUseCase(this._repository);

  Future<LoyaltyWallet> call() {
    return _repository.getLoyaltyWallet();
  }
}
