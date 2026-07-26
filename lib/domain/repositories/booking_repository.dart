import '../entities/booking.dart';
import '../entities/booking_quote.dart';
import '../entities/concession.dart';
import '../entities/loyalty_wallet.dart';
import '../entities/seat.dart';
import '../entities/seat_hold_session.dart';

abstract class BookingRepository {
  Future<Booking> getBookingById(String id);
  Future<String> createPaymentUrl(String bookingId);
  Future<List<Seat>> getSeats(String showtimeId);
  Future<List<Concession>> getConcessions();
  Future<LoyaltyWallet> getLoyaltyWallet();
  Future<SeatHoldSession> holdSeats(
    String showtimeId,
    List<String> seatIds, {
    String? holdSessionId,
  });
  Future<BookingQuote> quoteBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
  );
  Future<Booking> createBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
  );
}
