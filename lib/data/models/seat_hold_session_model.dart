import '../../domain/entities/seat_hold_session.dart';

class SeatHoldSessionModel extends SeatHoldSession {
  const SeatHoldSessionModel({
    required super.id,
    required super.status,
    required super.serverTime,
    required super.expiresAt,
  });

  factory SeatHoldSessionModel.fromJson(Map<String, dynamic> json) {
    return SeatHoldSessionModel(
      id: json['holdSessionId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      serverTime: DateTime.parse(json['serverTime'].toString()).toUtc(),
      expiresAt: json['expiredAt'] == null
          ? null
          : DateTime.parse(json['expiredAt'].toString()).toUtc(),
    );
  }
}
