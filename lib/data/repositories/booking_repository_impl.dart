import '../../domain/entities/booking.dart';
import '../../domain/entities/concession.dart';
import '../../domain/entities/seat.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Seat>> getSeats(String showtimeId) async {
    return await remoteDataSource.getSeats(showtimeId);
  }

  @override
  Future<List<Concession>> getConcessions() async {
    return await remoteDataSource.getConcessions();
  }

  @override
  Future<Booking> createBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
  ) async {
    return await remoteDataSource.createBooking(
        showtimeId, seatIds, concessions);
  }
}
