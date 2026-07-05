import '../entities/booking.dart';
import '../entities/concession.dart';
import '../entities/seat.dart';
import '../repositories/booking_repository.dart';

class GetSeatsUseCase {
  final BookingRepository _repository;

  GetSeatsUseCase(this._repository);

  Future<List<Seat>> call(String showtimeId) {
    return _repository.getSeats(showtimeId);
  }
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
  ) {
    return _repository.createBooking(showtimeId, seatIds, concessions);
  }
}
