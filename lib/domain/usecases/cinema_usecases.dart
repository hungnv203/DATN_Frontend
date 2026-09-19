import '../entities/cinema.dart';
import '../entities/showtime.dart';
import '../repositories/cinema_repository.dart';

class GetCinemasUseCase {
  final CinemaRepository _repository;

  GetCinemasUseCase(this._repository);

  Future<List<Cinema>> call() {
    return _repository.getCinemas();
  }
}

class GetShowtimesUseCase {
  final CinemaRepository _repository;
  final DateTime Function() _now;

  GetShowtimesUseCase(
    this._repository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Future<List<Showtime>> call(String movieId, String date) async {
    final showtimes = await _repository.getShowtimes(movieId, date);
    final now = _now();

    return showtimes
        .where((showtime) => showtime.startTime.isAfter(now))
        .toList(growable: false);
  }
}

class GetShowtimeByIdUseCase {
  GetShowtimeByIdUseCase(this._repository);

  final CinemaRepository _repository;

  Future<Showtime> call(String id) {
    return _repository.getShowtimeById(id);
  }
}
