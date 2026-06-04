import '../entities/ticket.dart';

abstract class TicketRepository {
  Future<List<Ticket>> getMyTickets();
}
