class SeatHoldSession {
  final String holdGroupId;
  final String showtimeId;
  final List<String> seatIds;
  final String status;
  final DateTime expiresAtUtc;
  final DateTime serverTimeUtc;

  const SeatHoldSession(
      {required this.holdGroupId,
      required this.showtimeId,
      required this.seatIds,
      required this.status,
      required this.expiresAtUtc,
      required this.serverTimeUtc});
  bool get isActive => status == 'Active';
}
