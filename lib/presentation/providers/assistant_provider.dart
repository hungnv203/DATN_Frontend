import 'package:flutter/foundation.dart';

import '../../domain/entities/assistant_response.dart';
import '../../domain/usecases/assistant_usecases.dart';

enum AssistantState { idle, checking, ready, sending, unavailable, error }

class AssistantProvider extends ChangeNotifier {
  AssistantProvider(this._getAvailability, this._sendMessage);

  final GetAssistantAvailabilityUseCase _getAvailability;
  final SendAssistantMessageUseCase _sendMessage;

  AssistantState _state = AssistantState.idle;
  final List<AssistantChatMessage> _messages = [];
  String? _errorMessage;
  String? _lastFailedMessage;
  bool _disposed = false;

  AssistantState get state => _state;
  List<AssistantChatMessage> get messages => List.unmodifiable(_messages);
  String? get errorMessage => _errorMessage;
  bool get isAvailable =>
      _state != AssistantState.unavailable || _messages.isNotEmpty;
  bool get isSending => _state == AssistantState.sending;

  Future<void> checkAvailability() async {
    if (_state == AssistantState.checking) return;
    if (_messages.isEmpty) {
      _state = AssistantState.checking;
    }
    _errorMessage = null;
    _notify();
    try {
      final enabled = await _getAvailability();
      if (_messages.isEmpty) {
        _state = enabled ? AssistantState.ready : AssistantState.unavailable;
      }
    } catch (_) {
      if (_messages.isEmpty) {
        _state = AssistantState.unavailable;
      }
    }
    _notify();
  }

  Future<void> send(String rawMessage, String locale) async {
    final message = rawMessage.trim();
    if (message.isEmpty || message.length > 1000 || isSending) return;

    // Send only up to the last 10 messages of history to avoid exceeding backend limits
    final history = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : List<AssistantChatMessage>.from(_messages);
    _messages.add(AssistantChatMessage(role: 'user', content: message));
    _state = AssistantState.sending;
    _errorMessage = null;
    _lastFailedMessage = null;
    _notify();

    try {
      final response = await _sendMessage(
        message: message,
        locale: locale,
        history: history,
      );
      _messages.add(
        AssistantChatMessage(
          role: 'assistant',
          content: response.text,
          response: response,
        ),
      );
      // Keep state ready so the input box stays open and the user can continue chatting
      _state = AssistantState.ready;
    } catch (_) {
      _lastFailedMessage = message;
      final errorText = locale.startsWith('en')
          ? 'The movie assistant is temporarily busy or overloaded. Please try again in a moment.'
          : 'Trợ lý phim hiện đang quá tải hoặc kết nối bị gián đoạn. Bạn vui lòng thử lại sau giây lát nhé.';
      _errorMessage = errorText;
      _messages.add(
        AssistantChatMessage(
          role: 'assistant',
          content: errorText,
        ),
      );
      _state = AssistantState.ready;
    }
    _notify();
  }

  Future<void> retry(String locale) async {
    final message = _lastFailedMessage;
    if (message == null || isSending) return;
    if (_messages.isNotEmpty && _messages.last.role == 'user') {
      _messages.removeLast();
    }
    await send(message, locale);
  }

  void clearSession() {
    _messages.clear();
    _errorMessage = null;
    _lastFailedMessage = null;
    _state = AssistantState.idle;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _messages.clear();
    super.dispose();
  }
}
