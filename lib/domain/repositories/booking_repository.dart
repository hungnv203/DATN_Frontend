import '../entities/booking.dart';
import '../entities/booking_quote.dart';
import '../entities/concession.dart';
import '../entities/loyalty_wallet.dart';
import '../entities/seat.dart';

abstract class BookingRepository {
  Future<List<Seat>> getSeats(String showtimeId);
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
  );
}
