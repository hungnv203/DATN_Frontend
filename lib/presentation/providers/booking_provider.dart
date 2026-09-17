import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/error/seat_hold_exceptions.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_quote.dart';
import '../../domain/entities/concession.dart';
import '../../domain/entities/loyalty_wallet.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/seat_hold_session.dart';
import '../../domain/entities/seat_realtime_state.dart';
import '../../domain/repositories/seat_realtime_repository.dart';
import '../../domain/usecases/booking_usecases.dart';
import '../booking_flow/booking_flow_strings.dart';

typedef BookingFlowTickerFactory = Timer Function(
    Duration interval, void Function(Timer timer) callback);

enum BookingState { initial, loading, success, error }

enum BookingFlowPhase {
  idle,
  initializing,
  selectingSeats,
  holding,
  selectingConcessions,
  reviewing,
  creatingBooking,
  paymentPending,
  paymentCompleted,
  paymentFailed,
  reviewRequired,
  validatingExpiry,
  expired,
  cancelling
}

abstract class BookingFlowClock {
  DateTime nowUtc();
}

class SystemBookingFlowClock implements BookingFlowClock {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

class BookingProvider extends ChangeNotifier {
  BookingProvider(
    this._getSeats,
    this._createSeatHold,
    this._getOwnedSeatHold,
    this._replaceSeatHold,
    this._releaseSeatHold,
    this._getConcessions,
    this._createBooking,
    this._quoteBooking,
    this._getLoyaltyWallet,
    this._getBookingById,
    this._createPaymentUrl,
    this._realtimeRepository, {
    HandlePaymentReturnUseCase? handlePaymentReturn,
    BookingFlowClock? clock,
    BookingFlowTickerFactory? tickerFactory,
  })  : _handlePaymentReturn = handlePaymentReturn,
        _clock = clock ?? SystemBookingFlowClock(),
        _tickerFactory = tickerFactory ?? Timer.periodic;

  final GetSeatsUseCase _getSeats;
  final CreateSeatHoldUseCase _createSeatHold;
  final GetOwnedSeatHoldUseCase _getOwnedSeatHold;
  final ReplaceSeatHoldUseCase _replaceSeatHold;
  final ReleaseSeatHoldUseCase _releaseSeatHold;
  final GetConcessionsUseCase _getConcessions;
  final CreateBookingUseCase _createBooking;
  final QuoteBookingUseCase _quoteBooking;
  final GetLoyaltyWalletUseCase _getLoyaltyWallet;
  final GetBookingByIdUseCase _getBookingById;
  final CreatePaymentUrlUseCase _createPaymentUrl;
  final HandlePaymentReturnUseCase? _handlePaymentReturn;
  final SeatRealtimeRepository _realtimeRepository;
  final BookingFlowClock _clock;
  final BookingFlowTickerFactory _tickerFactory;

  BookingState state = BookingState.initial;
  BookingFlowPhase phase = BookingFlowPhase.idle;
  String? errorMessage;
  String? showtimeId;
  List<Seat> seats = [];
  List<Seat> selectedSeats = [];
  List<Concession> concessions = [];
  Map<String, int> selectedConcessions = {};
  Booking? currentBooking;
  BookingQuote? currentQuote;
  LoyaltyWallet? loyaltyWallet;
  SeatHoldSession? holdSession;
  SeatHoldSession? recoverableHoldSession;
  String promotionCode = '';
  int usedPoints = 0;
  bool quoteIsStale = true;
  int seatStateVersion = 0;
  SeatRealtimeConnectionState realtimeState =
      SeatRealtimeConnectionState.disconnected;

  int _generation = 0;
  int _quoteVersion = 0;
  int _snapshotRequest = 0;
  String? _quoteFingerprint;
  Duration _serverOffset = Duration.zero;
  Timer? _ticker;
  Timer? _quoteDebounce;
  bool _expiryValidationRunning = false;
  StreamSubscription<SeatStateEvent>? _eventSubscription;
  StreamSubscription<SeatRealtimeConnectionState>? _connectionSubscription;
  final List<SeatStateEvent> _eventBuffer = [];
  final Set<String> _eventIds = {};
  bool _installingSnapshot = false;
  bool _resyncing = false;

  bool get commandInProgress =>
      phase == BookingFlowPhase.holding ||
      phase == BookingFlowPhase.creatingBooking ||
      phase == BookingFlowPhase.cancelling ||
      phase == BookingFlowPhase.validatingExpiry;
  bool get hasActiveHold =>
      holdSession?.isActive == true && remainingHoldTime > Duration.zero;
  Duration get remainingHoldTime {
    final session = holdSession;
    if (session == null) return Duration.zero;
    final value =
        session.expiresAtUtc.difference(_clock.nowUtc().add(_serverOffset));
    return value.isNegative ? Duration.zero : value;
  }

  bool get canConfirmBooking =>
      phase == BookingFlowPhase.reviewing &&
      hasActiveHold &&
      currentQuote != null &&
      !quoteIsStale &&
      _quoteFingerprint == _currentFingerprint();

  Future<void> startFlow(String id) async {
    if (showtimeId == id &&
        phase != BookingFlowPhase.idle &&
        phase != BookingFlowPhase.expired) {
      await loadSeatStage();
      return;
    }
    _generation++;
    final generation = _generation;
    await _disconnectRealtime();
    _resetValues();
    showtimeId = id;
    phase = BookingFlowPhase.initializing;
    state = BookingState.loading;
    notifyListeners();
    await _startRealtime(id);
    if (generation != _generation) return;
    final recoverable = recoverableHoldSession;
    if (recoverable != null && recoverable.showtimeId == id) {
      await _recoverHold(recoverable);
    }
    phase = BookingFlowPhase.selectingSeats;
    state = BookingState.success;
    notifyListeners();
  }

  Future<void> loadSeatStage() async {
    final id = showtimeId;
    if (id == null) return;
    await _installSnapshot(id);
    notifyListeners();
  }

  Future<void> loadConcessionStage() async {
    final generation = _generation;
    final id = showtimeId;
    if (id == null) return;
    if (concessions.isEmpty) {
      final loaded = await _getConcessions();
      if (!_isCurrentFlow(generation, id)) return;
      concessions = loaded;
    }
    phase = BookingFlowPhase.selectingConcessions;
    await quoteCurrentSelection(immediate: true);
    if (!_isCurrentFlow(generation, id)) return;
    notifyListeners();
  }

  Future<void> loadReviewStage() async {
    final generation = _generation;
    final id = showtimeId;
    if (id == null) return;
    try {
      if (loyaltyWallet == null) {
        final loaded = await _getLoyaltyWallet();
        if (!_isCurrentFlow(generation, id)) return;
        loyaltyWallet = loaded;
      }
    } catch (_) {
      if (!_isCurrentFlow(generation, id)) return;
      loyaltyWallet = null;
    }
    phase = holdSession == null
        ? BookingFlowPhase.selectingSeats
        : (currentBooking != null && currentBooking!.status == 'Pending')
            ? BookingFlowPhase.paymentPending
            : BookingFlowPhase.reviewing;
    await quoteCurrentSelection(immediate: true);
    if (!_isCurrentFlow(generation, id)) return;
    notifyListeners();
  }

  Future<void> loadLoyaltyWallet() async {
    try {
      loyaltyWallet = await _getLoyaltyWallet();
      notifyListeners();
    } catch (error) {
      errorMessage = BookingFlowErrorKeys.requestFailed;
      notifyListeners();
    }
  }

  void toggleSeatSelection(Seat seat) {
    if (commandInProgress || phase == BookingFlowPhase.paymentPending) return;
    final selectable = seat.status == 'Available' || seat.heldByCurrentUser;
    if (!selectable) return;
    final index = selectedSeats.indexWhere((item) => item.id == seat.id);
    index >= 0 ? selectedSeats.removeAt(index) : selectedSeats.add(seat);
    quoteIsStale = true;
    notifyListeners();
  }

  Future<bool> confirmSeats() async {
    final id = showtimeId;
    if (id == null || selectedSeats.isEmpty || commandInProgress) return false;
    final generation = _generation;
    phase = BookingFlowPhase.holding;
    errorMessage = null;
    final ids = selectedSeats.map((seat) => seat.id).toList();
    notifyListeners();
    try {
      final session = holdSession == null
          ? await _createSeatHold(id, ids)
          : await _replaceSeatHold(holdSession!.holdGroupId, id, ids);
      if (!_isCurrentFlow(generation, id)) {
        try {
          await _releaseSeatHold(session.holdGroupId);
        } catch (_) {
          // The backend TTL remains the fallback for a late orphan response.
        }
        return false;
      }
      _installHold(session);
      _drainEvents();
      phase = BookingFlowPhase.selectingConcessions;
      await loadConcessionStage();
      return true;
    } on SeatHoldConflict {
      errorMessage = BookingFlowErrorKeys.seatUnavailable;
      await _installSnapshot(id);
      phase = BookingFlowPhase.selectingSeats;
      return false;
    } catch (_) {
      errorMessage = BookingFlowErrorKeys.requestFailed;
      phase = BookingFlowPhase.selectingSeats;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> releaseFlow() async {
    if (phase == BookingFlowPhase.paymentPending) return false;
    if (commandInProgress) return false;
    final session = holdSession;
    if (session == null) {
      await _disconnectRealtime();
      resetFlow();
      return true;
    }
    phase = BookingFlowPhase.cancelling;
    notifyListeners();
    try {
      await _releaseSeatHold(session.holdGroupId);
      await _disconnectRealtime();
      resetFlow();
      return true;
    } on SeatHoldUnavailable {
      await _disconnectRealtime();
      resetFlow();
      return true;
    } catch (error) {
      errorMessage = BookingFlowErrorKeys.requestFailed;
      phase = BookingFlowPhase.selectingSeats;
      notifyListeners();
      return false;
    }
  }

  Future<void> leaveWithTtl() async {
    recoverableHoldSession = holdSession;
    _ticker?.cancel();
    await _disconnectRealtime();
    phase = BookingFlowPhase.idle;
    notifyListeners();
  }

  Future<bool> releaseHeldSelection() async {
    if (holdSession == null || commandInProgress) return false;
    final id = showtimeId;
    final session = holdSession!;
    phase = BookingFlowPhase.cancelling;
    notifyListeners();
    try {
      await _releaseSeatHold(session.holdGroupId);
      _ticker?.cancel();
      holdSession = null;
      recoverableHoldSession = null;
      selectedSeats = [];
      phase = BookingFlowPhase.selectingSeats;
      if (id != null) await _installSnapshot(id);
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = BookingFlowErrorKeys.requestFailed;
      phase = BookingFlowPhase.selectingSeats;
      notifyListeners();
      return false;
    }
  }

  void incrementConcession(Concession item) {
    selectedConcessions[item.id] = getConcessionQuantity(item.id) + 1;
    _markQuoteDirty(true);
  }

  void decrementConcession(Concession item) {
    final value = getConcessionQuantity(item.id);
    if (value <= 1) {
      selectedConcessions.remove(item.id);
    } else {
      selectedConcessions[item.id] = value - 1;
    }
    _markQuoteDirty(true);
  }

  int getConcessionQuantity(String id) => selectedConcessions[id] ?? 0;
  void updatePromotionCode(String value) {
    promotionCode = value.trim();
    _markQuoteDirty(false);
  }

  void updateUsedPoints(String value) {
    usedPoints = (int.tryParse(value) ?? 0).clamp(0, 1 << 31).toInt();
    _markQuoteDirty(false);
  }

  void _markQuoteDirty(bool immediate) {
    quoteIsStale = true;
    notifyListeners();
    immediate
        ? quoteCurrentSelection(immediate: true)
        : quoteCurrentSelection();
  }

  Future<void> quoteCurrentSelection({bool immediate = false}) async {
    _quoteDebounce?.cancel();
    if (!immediate) {
      _quoteDebounce =
          Timer(const Duration(milliseconds: 400), () => _requestQuote());
      return;
    }
    await _requestQuote();
  }

  Future<void> _requestQuote() async {
    final id = showtimeId;
    if (id == null || selectedSeats.isEmpty || !hasActiveHold) return;
    final generation = _generation;
    final request = ++_quoteVersion;
    final fingerprint = _currentFingerprint();
    try {
      final quote = await _quoteBooking(
          id,
          selectedSeats.map((seat) => seat.id).toList(),
          selectedConcessions,
          promotionCode.isEmpty ? null : promotionCode,
          usedPoints);
      if (request != _quoteVersion || !_isCurrentFlow(generation, id)) return;
      currentQuote = quote;
      _quoteFingerprint = fingerprint;
      quoteIsStale = fingerprint != _currentFingerprint();
      errorMessage = null;
    } catch (error) {
      if (request != _quoteVersion || !_isCurrentFlow(generation, id)) return;
      quoteIsStale = true;
      errorMessage = BookingFlowErrorKeys.requestFailed;
    }
    notifyListeners();
  }

  String _currentFingerprint() {
    final seatIds = selectedSeats.map((seat) => seat.id).toList()..sort();
    final concessions = selectedConcessions.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '${seatIds.join(',')}|${concessions.map((e) => '${e.key}:${e.value}').join(',')}|${promotionCode.trim()}|$usedPoints';
  }

  Future<bool> createPendingBooking() async {
    final id = showtimeId;
    final session = holdSession;
    if (currentBooking != null &&
        currentBooking!.status == 'Pending' &&
        currentBooking!.showtimeId == id) {
      phase = BookingFlowPhase.paymentPending;
      notifyListeners();
      return true;
    }
    if (!canConfirmBooking || id == null || session == null) return false;
    phase = BookingFlowPhase.creatingBooking;
    notifyListeners();
    try {
      currentBooking = await _createBooking(
          id,
          selectedSeats.map((seat) => seat.id).toList(),
          selectedConcessions,
          promotionCode.isEmpty ? null : promotionCode,
          usedPoints,
          session.holdGroupId);
      phase = BookingFlowPhase.paymentPending;
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = BookingFlowErrorKeys.requestFailed;
      phase = BookingFlowPhase.reviewing;
      notifyListeners();
      return false;
    }
  }

  void returnFromPayment() {
    if (phase == BookingFlowPhase.paymentPending) {
      switch (currentBooking?.status) {
        case 'Paid':
          phase = BookingFlowPhase.paymentCompleted;
          errorMessage = null;
          break;
        case 'Failed':
        case 'Cancelled':
        case 'Expired':
          phase = BookingFlowPhase.paymentFailed;
          errorMessage = BookingFlowErrorKeys.requestFailed;
          break;
        default:
          errorMessage = BookingFlowErrorKeys.paymentPending;
          break;
      }
      notifyListeners();
    }
  }

  Future<Booking?> fetchBookingById(String id) async {
    try {
      currentBooking = await _getBookingById(id);
      notifyListeners();
      return currentBooking;
    } catch (e) {
      errorMessage = BookingFlowErrorKeys.requestFailed;
      notifyListeners();
      return null;
    }
  }

  Future<String?> pollPaymentStatus(String id,
      {int maxAttempts = 5, Duration interval = const Duration(seconds: 1)}) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final booking = await fetchBookingById(id);
      final status = booking?.status;
      if (status == 'Paid' ||
          status == 'Failed' ||
          status == 'Cancelled' ||
          status == 'Expired') {
        return status;
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(interval);
      }
    }
    return currentBooking?.status;
  }

  Future<String?> createPaymentUrl(String id) async {
    try {
      return await _createPaymentUrl(id);
    } catch (e) {
      errorMessage = BookingFlowErrorKeys.requestFailed;
      notifyListeners();
      return null;
    }
  }

  Future<void> handlePaymentReturn(Map<String, String> queryParameters) async {
    final useCase = _handlePaymentReturn;
    if (useCase != null) {
      try {
        await useCase(queryParameters);
      } catch (_) {
        // Best effort: booking status polling will determine the actual state.
      }
    }
  }

  void _installHold(SeatHoldSession session) {
    holdSession = session;
    _serverOffset = session.serverTimeUtc.difference(_clock.nowUtc());
    _ticker?.cancel();
    _ticker = _tickerFactory(const Duration(seconds: 1), (_) {
      if (remainingHoldTime == Duration.zero) {
        _ticker?.cancel();
        _validateExpiry();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> _validateExpiry() async {
    if (_expiryValidationRunning || holdSession == null) return;
    _expiryValidationRunning = true;
    final prior = phase;
    phase = BookingFlowPhase.validatingExpiry;
    notifyListeners();
    try {
      final session = await _getOwnedSeatHold(holdSession!.holdGroupId);
      if (session.isActive) {
        _installHold(session);
        phase = prior;
      } else {
        await _expireFlow();
      }
    } on SeatHoldUnavailable {
      await _expireFlow();
    } on SeatHoldAuthenticationRequired {
      errorMessage = BookingFlowErrorKeys.authenticationRequired;
    } catch (error) {
      errorMessage = BookingFlowErrorKeys.requestFailed;
    } finally {
      _expiryValidationRunning = false;
      notifyListeners();
    }
  }

  Future<void> retryExpiryValidation() => _validateExpiry();
  Future<void> handleAppResumed() async {
    if (holdSession != null) await _validateExpiry();
    if (showtimeId != null) await _resync(showtimeId!);
  }

  void enterSeatStage() {
    if (phase != BookingFlowPhase.paymentPending) {
      phase = BookingFlowPhase.selectingSeats;
      notifyListeners();
    }
  }

  void enterConcessionStage() {
    if (phase != BookingFlowPhase.paymentPending) {
      phase = BookingFlowPhase.selectingConcessions;
      notifyListeners();
    }
  }

  Future<void> _expireFlow() async {
    _ticker?.cancel();
    holdSession = null;
    phase = BookingFlowPhase.expired;
    if (showtimeId != null) await _installSnapshot(showtimeId!);
    phase = BookingFlowPhase.selectingSeats;
    errorMessage = BookingFlowErrorKeys.holdExpired;
  }

  Future<void> _recoverHold(SeatHoldSession session) async {
    try {
      final current = await _getOwnedSeatHold(session.holdGroupId);
      if (current.isActive) {
        _installHold(current);
        selectedSeats =
            seats.where((seat) => current.seatIds.contains(seat.id)).toList();
      } else {
        recoverableHoldSession = null;
      }
    } catch (_) {
      recoverableHoldSession = session;
    }
  }

  Future<void> _startRealtime(String id) async {
    _eventSubscription = _realtimeRepository.events.listen(_handleSeatEvent);
    _connectionSubscription =
        _realtimeRepository.connectionStates.listen((value) {
      realtimeState = value;
      if (value == SeatRealtimeConnectionState.connected &&
          seatStateVersion > 0) {
        _resync(id);
      }
      notifyListeners();
    });
    await _realtimeRepository.connect(id);
    await _installSnapshot(id);
  }

  Future<void> _installSnapshot(String id) async {
    final generation = _generation;
    final request = ++_snapshotRequest;
    _installingSnapshot = true;
    final selectedIds = selectedSeats.map((seat) => seat.id).toSet();
    late List<Seat> loadedSeats;
    int loadedVersion = 0;
    var disconnected = false;
    try {
      final snapshot = await _realtimeRepository.getSnapshot(id);
      loadedSeats = snapshot.seats;
      loadedVersion = snapshot.version;
    } catch (_) {
      loadedSeats = await _getSeats(id);
      disconnected = true;
    }
    if (!_isCurrentFlow(generation, id) || request != _snapshotRequest) {
      return;
    }
    seats = loadedSeats;
    seatStateVersion = loadedVersion;
    if (disconnected) {
      realtimeState = SeatRealtimeConnectionState.disconnected;
    }
    final priorCount = selectedIds.length;
    selectedSeats = seats
        .where((seat) =>
            selectedIds.contains(seat.id) &&
            (seat.status == 'Available' || seat.heldByCurrentUser))
        .toList();
    if (selectedSeats.length < priorCount) {
      errorMessage = BookingFlowErrorKeys.seatUnavailable;
    }
    _installingSnapshot = false;
    _drainEvents();
  }

  void _handleSeatEvent(SeatStateEvent event) {
    if (event.showtimeId != showtimeId || _eventIds.contains(event.eventId)) {
      return;
    }
    if (phase == BookingFlowPhase.holding ||
        _installingSnapshot ||
        event.version > seatStateVersion + 1) {
      _eventBuffer.add(event);
      if (phase != BookingFlowPhase.holding && !_installingSnapshot) {
        _resync(event.showtimeId);
      }
      return;
    }
    if (event.version > seatStateVersion) _applyEvent(event);
  }

  void _applyEvent(SeatStateEvent event) {
    _eventIds.add(event.eventId);
    for (final change in event.changes) {
      final index = seats.indexWhere((seat) => seat.id == change.seatId);
      if (index < 0) continue;
      final owned = change.holdGroupId == holdSession?.holdGroupId;
      seats[index] = seats[index].copyWith(
          status: change.status,
          heldByCurrentUser: owned,
          expiresAtUtc: change.expiresAtUtc);
      if ((change.status == 'Held' && !owned) || change.status == 'Booked') {
        final removed = selectedSeats.any((seat) => seat.id == change.seatId);
        selectedSeats.removeWhere((seat) => seat.id == change.seatId);
        if (removed) errorMessage = BookingFlowErrorKeys.seatUnavailable;
      }
    }
    seatStateVersion = event.version;
    notifyListeners();
  }

  void _drainEvents() {
    _eventBuffer.sort((a, b) => a.version.compareTo(b.version));
    final pending = List<SeatStateEvent>.from(_eventBuffer);
    _eventBuffer.clear();
    for (final event in pending) {
      if (event.version == seatStateVersion + 1) {
        _applyEvent(event);
      } else if (event.version > seatStateVersion + 1) {
        _eventBuffer.add(event);
      }
    }
  }

  Future<void> _resync(String id) async {
    if (_resyncing) return;
    _resyncing = true;
    try {
      await _installSnapshot(id);
      if (_eventBuffer.isNotEmpty) await _installSnapshot(id);
    } finally {
      _resyncing = false;
    }
  }

  Future<void> _disconnectRealtime() async {
    await _eventSubscription?.cancel();
    await _connectionSubscription?.cancel();
    if (showtimeId != null) await _realtimeRepository.disconnect(showtimeId!);
    _eventSubscription = null;
    _connectionSubscription = null;
  }

  void resetFlow() {
    _generation++;
    _quoteVersion++;
    _snapshotRequest++;
    _ticker?.cancel();
    _quoteDebounce?.cancel();
    _resetValues();
    phase = BookingFlowPhase.idle;
    state = BookingState.initial;
    notifyListeners();
  }

  void _resetValues() {
    seats = [];
    selectedSeats = [];
    concessions = [];
    selectedConcessions = {};
    currentBooking = null;
    currentQuote = null;
    loyaltyWallet = null;
    holdSession = null;
    promotionCode = '';
    usedPoints = 0;
    quoteIsStale = true;
    errorMessage = null;
    seatStateVersion = 0;
    _quoteFingerprint = null;
    _installingSnapshot = false;
  }

  bool _isCurrentFlow(int generation, String id) =>
      generation == _generation && id == showtimeId;

  @override
  void dispose() {
    _ticker?.cancel();
    _quoteDebounce?.cancel();
    _eventSubscription?.cancel();
    _connectionSubscription?.cancel();
    if (showtimeId != null) _realtimeRepository.disconnect(showtimeId!);
    super.dispose();
  }
}
