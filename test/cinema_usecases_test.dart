import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/domain/entities/cinema.dart';
import 'package:movie_booking_app/domain/entities/showtime.dart';
import 'package:movie_booking_app/domain/repositories/cinema_repository.dart';
import 'package:movie_booking_app/domain/usecases/cinema_usecases.dart';

void main() {
  test('get showtimes hides started and expired showtimes', () async {
    final now = DateTime.utc(2026, 9, 19, 10);
    final repository = _FakeCinemaRepository([
      _showtime('past', now.subtract(const Duration(minutes: 1))),
      _showtime('starting-now', now),
      _showtime('future', now.add(const Duration(minutes: 1))),
    ]);
    final useCase = GetShowtimesUseCase(repository, now: () => now);

    final result = await useCase('movie-1', '2026-09-19');

    expect(result.map((showtime) => showtime.id), ['future']);
    expect(repository.requestedMovieId, 'movie-1');
    expect(repository.requestedDate, '2026-09-19');
  });
}

Showtime _showtime(String id, DateTime startTime) => Showtime(
      id: id,
      movieId: 'movie-1',
      roomId: 'room-1',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 2)),
      basePrice: 100000,
      status: 'Scheduled',
    );

class _FakeCinemaRepository implements CinemaRepository {
  _FakeCinemaRepository(this.showtimes);

  final List<Showtime> showtimes;
  String? requestedMovieId;
  String? requestedDate;

  @override
  Future<List<Showtime>> getShowtimes(String movieId, String date) async {
    requestedMovieId = movieId;
    requestedDate = date;
    return showtimes;
  }

  @override
  Future<List<Cinema>> getCinemas() => throw UnimplementedError();

  @override
  Future<Showtime> getShowtimeById(String id) => throw UnimplementedError();
}
