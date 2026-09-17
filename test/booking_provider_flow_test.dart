import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/core/error/seat_hold_exceptions.dart';
import 'package:movie_booking_app/domain/entities/booking.dart';
import 'package:movie_booking_app/domain/entities/booking_quote.dart';
import 'package:movie_booking_app/domain/entities/concession.dart';
import 'package:movie_booking_app/domain/entities/loyalty_wallet.dart';
import 'package:movie_booking_app/domain/entities/seat.dart';
import 'package:movie_booking_app/domain/entities/seat_hold_session.dart';
import 'package:movie_booking_app/domain/entities/seat_realtime_state.dart';
import 'package:movie_booking_app/domain/repositories/booking_repository.dart';
import 'package:movie_booking_app/domain/repositories/seat_realtime_repository.dart';
import 'package:movie_booking_app/domain/usecases/booking_usecases.dart';
import 'package:movie_booking_app/presentation/booking_flow/booking_flow_strings.dart';
import 'package:movie_booking_app/presentation/providers/booking_provider.dart';

void main() {
  test('local multi-selection sends one complete hold only after confirmation',
      () async {
    final repository = _FakeBookingRepository();
    final provider = _provider(repository);
    await provider.startFlow('showtime-1');

    provider.toggleSeatSelection(repository.seats[0]);
    provider.toggleSeatSelection(repository.seats[1]);
    expect(repository.createHoldCalls, 0);
    expect(provider.selectedSeats.map((seat) => seat.id), ['A1', 'A2']);

    final first = provider.confirmSeats();
    final duplicate = await provider.confirmSeats();
    expect(duplicate, isFalse);
    repository.holdCompleter.complete(repository.session());
    expect(await first, isTrue);
    expect(repository.createHoldCalls, 1);
    expect(repository.lastHeldSeatIds, ['A1', 'A2']);
    provider.dispose();
  });

  test('expiry authentication failure cancels ticker and waits for retry',
      () async {
    final repository = _FakeBookingRepository()
      ..ownedHoldError = const SeatHoldAuthenticationRequired();
    late _FakeTimer ticker;
    final provider = _provider(repository,
        tickerFactory: (_, callback) => ticker = _FakeTimer(callback));
    await provider.startFlow('showtime-1');
    provider.toggleSeatSelection(repository.seats.first);
    repository.holdCompleter.complete(repository.session(expired: true));
    await provider.confirmSeats();

    ticker.fire();
    await Future<void>.delayed(Duration.zero);
    expect(ticker.isActive, isFalse);
    expect(repository.getOwnedHoldCalls, 1);
    expect(provider.errorMessage, BookingFlowErrorKeys.authenticationRequired);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repository.getOwnedHoldCalls, 1);
    provider.dispose();
  });

  test('late hold response cannot restore a reset flow', () async {
    final repository = _FakeBookingRepository();
    final provider = _provider(repository);
    await provider.startFlow('showtime-1');
    provider.toggleSeatSelection(repository.seats.first);

    final confirmation = provider.confirmSeats();
    provider.resetFlow();
    repository.holdCompleter.complete(repository.session());

    expect(await confirmation, isFalse);
    expect(provider.phase, BookingFlowPhase.idle);
    expect(provider.holdSession, isNull);
    expect(repository.releaseHoldCalls, 1);
    provider.dispose();
  });

  test('own realtime hold event does not clear selection before hold response',
      () async {
    final repository = _FakeBookingRepository();
    final realtime = _FakeRealtimeRepository(repository.seats);
    final provider = _provider(repository, realtime: realtime);
    await provider.startFlow('showtime-1');
    provider.toggleSeatSelection(repository.seats.first);

    final confirmation = provider.confirmSeats();
    realtime.emit(
      const SeatStateEvent(
        eventId: 'hold-event',
        showtimeId: 'showtime-1',
        version: 2,
        changes: [
          SeatStateChange(
            seatId: 'A1',
            status: 'Held',
            holdGroupId: 'random-group',
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(provider.selectedSeats.map((seat) => seat.id), ['A1']);
    repository.holdCompleter.complete(repository.session());
    expect(await confirmation, isTrue);
    expect(provider.selectedSeats.map((seat) => seat.id), ['A1']);
    expect(provider.errorMessage, isNull);
    expect(provider.currentQuote, isNotNull);
    provider.dispose();
  });

  test('stale snapshot cannot overwrite a newer showtime flow', () async {
    final repository = _FakeBookingRepository();
    final realtime = _ControlledRealtimeRepository();
    final provider = _provider(repository, realtime: realtime);

    final oldFlow = provider.startFlow('old');
    await Future<void>.delayed(Duration.zero);
    final newFlow = provider.startFlow('new');
    await Future<void>.delayed(Duration.zero);
    realtime.complete(
        'new',
        const SeatStateSnapshot(2, [
          Seat(id: 'N1', roomId: 'room', row: 'N', number: 1, type: 'Standard')
        ]));
    await newFlow;
    realtime.complete(
        'old',
        const SeatStateSnapshot(1, [
          Seat(id: 'O1', roomId: 'room', row: 'O', number: 1, type: 'Standard')
        ]));
    await oldFlow;

    expect(provider.showtimeId, 'new');
    expect(provider.seats.map((seat) => seat.id), ['N1']);
    provider.dispose();
  });

  test('existing pending booking preserves paymentPending in loadReviewStage and delegates return', () async {
    final repository = _FakeBookingRepository();
    final provider = _provider(repository);
    await provider.startFlow('showtime-1');
    provider.toggleSeatSelection(repository.seats.first);
    repository.holdCompleter.complete(repository.session());
    await provider.confirmSeats();
    await provider.loadReviewStage();

    final created = await provider.createPendingBooking();
    expect(created, isTrue);
    expect(provider.phase, BookingFlowPhase.paymentPending);

    await provider.loadReviewStage();
    expect(provider.phase, BookingFlowPhase.paymentPending);

    await provider.handlePaymentReturn({'vnp_ResponseCode': '00'});
    expect(repository.lastPaymentReturnParameters, {'vnp_ResponseCode': '00'});

    provider.dispose();
  });
}

BookingProvider _provider(_FakeBookingRepository repository,
        {BookingFlowTickerFactory? tickerFactory,
        SeatRealtimeRepository? realtime}) =>
    BookingProvider(
      GetSeatsUseCase(repository),
      CreateSeatHoldUseCase(repository),
      GetOwnedSeatHoldUseCase(repository),
      ReplaceSeatHoldUseCase(repository),
      ReleaseSeatHoldUseCase(repository),
      GetConcessionsUseCase(repository),
      CreateBookingUseCase(repository),
      QuoteBookingUseCase(repository),
      GetLoyaltyWalletUseCase(repository),
      GetBookingByIdUseCase(repository),
      CreatePaymentUrlUseCase(repository),
      realtime ?? _FakeRealtimeRepository(repository.seats),
      handlePaymentReturn: HandlePaymentReturnUseCase(repository),
      tickerFactory: tickerFactory ?? (_, callback) => _FakeTimer(callback),
    );

class _FakeTimer implements Timer {
  _FakeTimer(this.callback);
  final void Function(Timer) callback;
  bool _active = true;
  int _tick = 0;
  void fire() {
    if (!_active) return;
    _tick++;
    callback(this);
  }

  @override
  void cancel() => _active = false;
  @override
  bool get isActive => _active;
  @override
  int get tick => _tick;
}

class _FakeRealtimeRepository implements SeatRealtimeRepository {
  _FakeRealtimeRepository(this.seats);
  final List<Seat> seats;
  final _events = StreamController<SeatStateEvent>.broadcast();
  final _connections =
      StreamController<SeatRealtimeConnectionState>.broadcast();
  @override
  Stream<SeatStateEvent> get events => _events.stream;
  @override
  Stream<SeatRealtimeConnectionState> get connectionStates =>
      _connections.stream;
  @override
  Future<void> connect(String showtimeId) async {}
  @override
  Future<void> disconnect(String showtimeId) async {}
  @override
  Future<void> dispose() async {
    await _events.close();
    await _connections.close();
  }

  @override
  Future<SeatStateSnapshot> getSnapshot(String showtimeId) async =>
      SeatStateSnapshot(1, List<Seat>.from(seats));

  void emit(SeatStateEvent event) => _events.add(event);
}

class _ControlledRealtimeRepository implements SeatRealtimeRepository {
  final _events = StreamController<SeatStateEvent>.broadcast();
  final _connections =
      StreamController<SeatRealtimeConnectionState>.broadcast();
  final Map<String, Completer<SeatStateSnapshot>> _snapshots = {};
  @override
  Stream<SeatStateEvent> get events => _events.stream;
  @override
  Stream<SeatRealtimeConnectionState> get connectionStates =>
      _connections.stream;
  @override
  Future<void> connect(String showtimeId) async {}
  @override
  Future<void> disconnect(String showtimeId) async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<SeatStateSnapshot> getSnapshot(String showtimeId) =>
      (_snapshots[showtimeId] ??= Completer<SeatStateSnapshot>()).future;
  void complete(String id, SeatStateSnapshot snapshot) =>
      (_snapshots[id] ??= Completer<SeatStateSnapshot>()).complete(snapshot);
}

class _FakeBookingRepository implements BookingRepository {
  final seats = const [
    Seat(id: 'A1', roomId: 'room', row: 'A', number: 1, type: 'Standard'),
    Seat(id: 'A2', roomId: 'room', row: 'A', number: 2, type: 'Standard'),
  ];
  int createHoldCalls = 0;
  int getOwnedHoldCalls = 0;
  int releaseHoldCalls = 0;
  List<String> lastHeldSeatIds = [];
  Object? ownedHoldError;
  Map<String, String>? lastPaymentReturnParameters;
  final holdCompleter = Completer<SeatHoldSession>();

  SeatHoldSession session({bool expired = false}) => SeatHoldSession(
        holdGroupId: 'random-group',
        showtimeId: 'showtime-1',
        seatIds: lastHeldSeatIds,
        status: 'Active',
        expiresAtUtc: DateTime.now()
            .toUtc()
            .add(expired ? Duration.zero : const Duration(minutes: 5)),
        serverTimeUtc: DateTime.now().toUtc(),
      );

  @override
  Future<SeatHoldSession> createSeatHold(
      String showtimeId, List<String> seatIds) {
    createHoldCalls++;
    lastHeldSeatIds = List<String>.from(seatIds);
    return holdCompleter.future;
  }

  @override
  Future<SeatHoldSession> getOwnedSeatHold(String holdGroupId) async {
    getOwnedHoldCalls++;
    if (ownedHoldError != null) throw ownedHoldError!;
    return session();
  }

  @override
  Future<List<Seat>> getSeats(String showtimeId) async => seats;
  @override
  Future<List<Concession>> getConcessions() async => [];
  @override
  Future<BookingQuote> quoteBooking(
          String showtimeId,
          List<String> seatIds,
          Map<String, int> concessions,
          String? promotionCode,
          int usedPoints) async =>
      const BookingQuote(
          seatTotal: 1,
          concessionTotal: 0,
          subtotal: 1,
          discountAmount: 0,
          usedPoints: 0,
          pointDiscountAmount: 0,
          totalPrice: 1);
  @override
  Future<void> releaseSeatHold(String holdGroupId) async {
    releaseHoldCalls++;
  }

  @override
  Future<SeatHoldSession> replaceSeatHold(
          String holdGroupId, String showtimeId, List<String> seatIds) async =>
      session();
  @override
  Future<LoyaltyWallet> getLoyaltyWallet() async =>
      const LoyaltyWallet(userId: 'user', points: 0, transactions: []);
  @override
  Future<Booking> createBooking(
          String showtimeId,
          List<String> seatIds,
          Map<String, int> concessions,
          String? promotionCode,
          int usedPoints,
          String seatHoldGroupId) async =>
      const Booking(
          id: 'booking',
          userId: 'user',
          showtimeId: 'showtime-1',
          status: 'Pending',
          totalPrice: 1);
  @override
  Future<Booking> getBookingById(String id) async => const Booking(
      id: 'booking',
      userId: 'user',
      showtimeId: 'showtime-1',
      status: 'Pending',
      totalPrice: 1);
  @override
  Future<String> createPaymentUrl(String bookingId) async =>
      'https://example.test';
  @override
  Future<void> handlePaymentReturn(Map<String, String> queryParameters) async {
    lastPaymentReturnParameters = queryParameters;
  }
}
