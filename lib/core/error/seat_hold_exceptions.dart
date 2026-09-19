class SeatHoldConflict implements Exception {
  final String message;
  final String? errorCode;
  const SeatHoldConflict(this.message, {this.errorCode});
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

class SeatHoldRateLimited implements Exception {
  final String message;
  const SeatHoldRateLimited(this.message);
}

class SeatHoldShowtimeNotBookable implements Exception {
  final String message;
  const SeatHoldShowtimeNotBookable(this.message);
}

class SeatHoldLimitExceeded implements Exception {
  final String message;
  const SeatHoldLimitExceeded(this.message);
}

class SeatHoldAlreadyBooked implements Exception {
  final String message;
  const SeatHoldAlreadyBooked(this.message);
}

class SeatHoldBookingAlreadyPending implements Exception {
  final String message;
  const SeatHoldBookingAlreadyPending(this.message);
}
