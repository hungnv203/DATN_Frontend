import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

class GetMyTicketsUseCase {
  final TicketRepository _repository;

  GetMyTicketsUseCase(this._repository);

  Future<List<Ticket>> call() {
    return _repository.getMyTickets();
  }
}
