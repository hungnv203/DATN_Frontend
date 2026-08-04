import '../../domain/entities/seat_hold_session.dart';

class SeatHoldSessionModel extends SeatHoldSession {
  const SeatHoldSessionModel(
      {required super.holdGroupId,
      required super.showtimeId,
      required super.seatIds,
      required super.status,
      required super.expiresAtUtc,
      required super.serverTimeUtc});

  factory SeatHoldSessionModel.fromJson(Map<String, dynamic> json) =>
      SeatHoldSessionModel(
        holdGroupId: json['holdGroupId']?.toString() ?? '',
        showtimeId: json['showtimeId']?.toString() ?? '',
        seatIds: (json['seatIds'] as List<dynamic>? ?? const [])
            .map((id) => id.toString())
            .toList(),
        status: json['status']?.toString() ?? 'Expired',
        expiresAtUtc: DateTime.parse(json['expiredAt'].toString()).toUtc(),
        serverTimeUtc: DateTime.parse(json['serverTimeUtc'].toString()).toUtc(),
      );
}
