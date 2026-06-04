import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_data_source.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;

  TicketRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Ticket>> getMyTickets() async {
    return await remoteDataSource.getMyTickets();
  }
}
