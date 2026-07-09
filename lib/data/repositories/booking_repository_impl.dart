import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_quote.dart';
import '../../domain/entities/concession.dart';
import '../../domain/entities/loyalty_wallet.dart';
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
  Future<LoyaltyWallet> getLoyaltyWallet() async {
    return await remoteDataSource.getLoyaltyWallet();
  }

  @override
  Future<BookingQuote> quoteBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
  ) async {
    return await remoteDataSource.quoteBooking(
      showtimeId,
      seatIds,
      concessions,
      promotionCode,
      usedPoints,
    );
  }

  @override
  Future<Booking> createBooking(
    String showtimeId,
    List<String> seatIds,
    Map<String, int> concessions,
    String? promotionCode,
    int usedPoints,
  ) async {
    return await remoteDataSource.createBooking(
      showtimeId,
      seatIds,
      concessions,
      promotionCode,
      usedPoints,
    );
  }
}
