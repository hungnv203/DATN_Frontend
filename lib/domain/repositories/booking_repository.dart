import '../entities/booking.dart';
import '../entities/concession.dart';
import '../entities/seat.dart';

abstract class BookingRepository {
  Future<List<Seat>> getSeats(String showtimeId);
  Future<List<Concession>> getConcessions();
  Future<Booking> createBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
  );
}
