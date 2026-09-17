import '../entities/booking.dart';
import '../entities/booking_quote.dart';
import '../entities/concession.dart';
import '../entities/loyalty_wallet.dart';
import '../entities/seat.dart';
import '../entities/seat_hold_session.dart';

abstract class BookingRepository {
  Future<Booking> getBookingById(String id);
  Future<String> createPaymentUrl(String bookingId);
  Future<void> handlePaymentReturn(Map<String, String> queryParameters);
  Future<List<Seat>> getSeats(String showtimeId);
  Future<SeatHoldSession> createSeatHold(
      String showtimeId, List<String> seatIds);
  Future<SeatHoldSession> getOwnedSeatHold(String holdGroupId);
  Future<SeatHoldSession> replaceSeatHold(
      String holdGroupId, String showtimeId, List<String> seatIds);
  Future<void> releaseSeatHold(String holdGroupId);
  Future<List<Concession>> getConcessions();
  Future<LoyaltyWallet> getLoyaltyWallet();
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
    String seatHoldGroupId,
  );
}
