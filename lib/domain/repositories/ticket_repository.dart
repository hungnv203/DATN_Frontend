import '../entities/ticket.dart';

abstract class TicketRepository {
  Future<List<Ticket>> getMyTickets();
  Future<List<Ticket>> getMySuccessfulTickets();
}
