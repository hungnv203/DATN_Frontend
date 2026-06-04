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

  GetShowtimesUseCase(this._repository);

  Future<List<Showtime>> call(String movieId, String date) {
    return _repository.getShowtimes(movieId, date);
  }
}
