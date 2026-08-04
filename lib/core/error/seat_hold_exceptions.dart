class SeatHoldConflict implements Exception {
  final String message;
  const SeatHoldConflict(this.message);
}

class SeatHoldUnavailable implements Exception {
  final String message;
  const SeatHoldUnavailable(this.message);
}

class SeatHoldAuthenticationRequired implements Exception {
  const SeatHoldAuthenticationRequired();
}

class SeatHoldTransportFailure implements Exception {
  final String message;
  const SeatHoldTransportFailure(this.message);
}
