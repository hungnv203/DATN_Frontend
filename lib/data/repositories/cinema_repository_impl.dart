import '../../domain/entities/cinema.dart';
import '../../domain/entities/showtime.dart';
import '../../domain/repositories/cinema_repository.dart';
import '../datasources/cinema_remote_data_source.dart';

class CinemaRepositoryImpl implements CinemaRepository {
  final CinemaRemoteDataSource remoteDataSource;

  CinemaRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Cinema>> getCinemas() async {
    return await remoteDataSource.getCinemas();
  }

  @override
  Future<List<Showtime>> getShowtimes(String movieId, String date) async {
    return await remoteDataSource.getShowtimes(movieId, date);
  }
}
