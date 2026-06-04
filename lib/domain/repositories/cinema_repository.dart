import '../entities/cinema.dart';
import '../entities/showtime.dart';

abstract class CinemaRepository {
  Future<List<Cinema>> getCinemas();
  Future<List<Showtime>> getShowtimes(String movieId, String date);
}
