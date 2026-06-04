import 'package:flutter/material.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/usecases/ticket_usecases.dart';

enum TicketState { initial, loading, success, error }

class TicketProvider extends ChangeNotifier {
  final GetMyTicketsUseCase _getMyTickets;

  TicketProvider(this._getMyTickets);

  TicketState state = TicketState.initial;
  String? errorMessage;

  List<Ticket> tickets = [];

  Future<void> fetchMyTickets() async {
    try {
      state = TicketState.loading;
      notifyListeners();

      tickets = await _getMyTickets();

      state = TicketState.success;
      notifyListeners();
    } catch (e) {
      state = TicketState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
