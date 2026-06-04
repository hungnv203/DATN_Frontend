import '../entities/booking.dart';
import '../entities/seat.dart';

abstract class BookingRepository {
  Future<List<Seat>> getSeats(String showtimeId);
  Future<Booking> createBooking(String showtimeId, List<String> seatIds);
}
