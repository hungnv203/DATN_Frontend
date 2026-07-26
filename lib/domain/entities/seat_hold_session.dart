class SeatHoldSession {
  final String id;
  final String status;
  final DateTime serverTime;
  final DateTime? expiresAt;

  const SeatHoldSession({
    required this.id,
    required this.status,
    required this.serverTime,
    required this.expiresAt,
  });

  bool get isActive => status == 'Active' && expiresAt != null;
}
