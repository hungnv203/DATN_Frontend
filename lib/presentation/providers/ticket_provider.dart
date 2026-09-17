import 'package:flutter/material.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/usecases/ticket_usecases.dart';

enum TicketState { initial, loading, success, error }

class TicketProvider extends ChangeNotifier {
  final GetMyTicketsUseCase _getMyTickets;
  final GetMySuccessfulTicketsUseCase _getMySuccessfulTickets;

  TicketProvider(this._getMyTickets, this._getMySuccessfulTickets);

  TicketState state = TicketState.initial;
  String? errorMessage;

  List<Ticket> tickets = [];
  bool onlySuccessful = false;

  Future<void> fetchMyTickets({bool onlySuccess = false}) async {
    try {
      onlySuccessful = onlySuccess;
      state = TicketState.loading;
      notifyListeners();

      if (onlySuccess) {
        tickets = await _getMySuccessfulTickets();
      } else {
        tickets = await _getMyTickets();
      }

      state = TicketState.success;
      notifyListeners();
    } catch (e) {
      state = TicketState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMySuccessfulTickets() => fetchMyTickets(onlySuccess: true);
}

