import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_core/signalr_core.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/seat_realtime_state.dart';
import '../../domain/repositories/seat_realtime_repository.dart';

class SeatRealtimeRepositoryImpl implements SeatRealtimeRepository {
  final DioClient _client;
  final SharedPreferences _preferences;
  final _events = StreamController<SeatStateEvent>.broadcast();
  final _states = StreamController<SeatRealtimeConnectionState>.broadcast();
  HubConnection? _connection;
  bool _authenticationRejected = false;

  SeatRealtimeRepositoryImpl(this._client, this._preferences);

  @override
  Stream<SeatStateEvent> get events => _events.stream;
  @override
  Stream<SeatRealtimeConnectionState> get connectionStates => _states.stream;

  @override
  Future<SeatStateSnapshot> getSnapshot(String showtimeId) async {
    final response = await _client.get('showtimes/$showtimeId/seat-state');
    final data = Map<String, dynamic>.from(response.data as Map);
    final items = (data['seats'] as List<dynamic>? ?? const [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .map((json) => Seat(
              id: json['seatId']?.toString() ?? '',
              roomId: json['roomId']?.toString() ?? '',
              row: json['rowLabel']?.toString() ?? '',
              number: json['seatNumber'] as int? ?? 0,
              type: json['type']?.toString() ?? 'Standard',
              status: json['status']?.toString() ?? 'Available',
              isAvailable: json['status'] == 'Available',
              heldByCurrentUser: json['heldByCurrentUser'] == true,
              expiresAtUtc: DateTime.tryParse(json['expiresAtUtc']?.toString() ?? ''),
            ))
        .toList();
    return SeatStateSnapshot(data['version'] as int? ?? 0, items);
  }

  @override
  Future<void> connect(String showtimeId) async {
    await disconnect(showtimeId);
    _states.add(SeatRealtimeConnectionState.connecting);
    _authenticationRejected = false;
    final rootUrl = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final connection = HubConnectionBuilder()
        .withUrl('$rootUrl/hubs/seats', HttpConnectionOptions(
          accessTokenFactory: () async => _preferences.getString('auth_token') ?? '',
          withCredentials: false,
        ))
        .withAutomaticReconnect()
        .build();
    _connection = connection;
    connection.on('SeatStatusChanged', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final json = Map<String, dynamic>.from(arguments.first as Map);
      _events.add(SeatStateEvent(
        eventId: json['eventId']?.toString() ?? '',
        showtimeId: json['showtimeId']?.toString() ?? '',
        version: json['version'] as int? ?? 0,
        changes: (json['changes'] as List<dynamic>? ?? const []).map((value) {
          final change = Map<String, dynamic>.from(value as Map);
          return SeatStateChange(
            seatId: change['seatId']?.toString() ?? '',
            status: change['status']?.toString() ?? 'Available',
            expiresAtUtc: DateTime.tryParse(change['expiresAtUtc']?.toString() ?? ''),
            holdGroupId: change['holdGroupId']?.toString(),
          );
        }).toList(),
      ));
    });
    connection.onreconnecting((error) {
      if (_isAuthenticationError(error)) {
        _authenticationRejected = true;
        _states.add(SeatRealtimeConnectionState.reauthenticationRequired);
        connection.stop();
      } else {
        _states.add(SeatRealtimeConnectionState.disconnected);
      }
    });
    connection.onreconnected((_) async {
      await connection.invoke('JoinShowtime', args: [showtimeId]);
      _states.add(SeatRealtimeConnectionState.connected);
    });
    connection.onclose((error) => _states.add(
      _authenticationRejected || _isAuthenticationError(error)
          ? SeatRealtimeConnectionState.reauthenticationRequired
          : SeatRealtimeConnectionState.disconnected,
    ));
    try {
      await connection.start();
      await connection.invoke('JoinShowtime', args: [showtimeId]);
      _states.add(SeatRealtimeConnectionState.connected);
    } catch (error) {
      _states.add(error.toString().contains('401')
          ? SeatRealtimeConnectionState.reauthenticationRequired
          : SeatRealtimeConnectionState.disconnected);
    }
  }

  bool _isAuthenticationError(Object? error) {
    final message = error?.toString().toLowerCase() ?? '';
    return message.contains('401') || message.contains('unauthorized') || message.contains('authentication');
  }

  @override
  Future<void> disconnect(String showtimeId) async {
    final connection = _connection;
    _connection = null;
    if (connection == null) return;
    if (connection.state == HubConnectionState.connected) {
      await connection.invoke('LeaveShowtime', args: [showtimeId]);
    }
    await connection.stop();
  }

  @override
  Future<void> dispose() async {
    await _connection?.stop();
    await _events.close();
    await _states.close();
  }
}
