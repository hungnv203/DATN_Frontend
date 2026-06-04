import '../entities/booking.dart';
import '../entities/seat.dart';
import '../repositories/booking_repository.dart';

class GetSeatsUseCase {
  final BookingRepository _repository;

  GetSeatsUseCase(this._repository);

  Future<List<Seat>> call(String showtimeId) {
    return _repository.getSeats(showtimeId);
  }
}

class CreateBookingUseCase {
  final BookingRepository _repository;

  CreateBookingUseCase(this._repository);

  Future<Booking> call(String showtimeId, List<String> seatIds) {
    return _repository.createBooking(showtimeId, seatIds);
  }
}
