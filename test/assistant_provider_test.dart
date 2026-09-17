import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/domain/entities/assistant_response.dart';
import 'package:movie_booking_app/domain/repositories/assistant_repository.dart';
import 'package:movie_booking_app/domain/usecases/assistant_usecases.dart';
import 'package:movie_booking_app/presentation/providers/assistant_provider.dart';

void main() {
  test('availability exposes ready only when server enables assistant', () async {
    final repository = _FakeAssistantRepository(available: true);
    final provider = _provider(repository);

    await provider.checkAvailability();

    expect(provider.state, AssistantState.ready);
  });

  test('pending guard accepts only one logical send', () async {
    final repository = _FakeAssistantRepository(available: true);
    final provider = _provider(repository);

    final first = provider.send('Recommend action movies', 'en');
    await provider.send('Duplicate', 'en');

    expect(repository.sendCount, 1);
    repository.completer.complete(_response());
    await first;
    expect(provider.messages.length, 2);
    expect(provider.state, AssistantState.ready);
  });

  test('clear session removes in-memory conversation', () async {
    final repository = _FakeAssistantRepository(available: true);
    final provider = _provider(repository);
    final send = provider.send('Hello', 'en');
    repository.completer.complete(_response());
    await send;

    provider.clearSession();

    expect(provider.messages, isEmpty);
    expect(provider.state, AssistantState.idle);
  });
}

AssistantProvider _provider(AssistantRepository repository) {
  return AssistantProvider(
    GetAssistantAvailabilityUseCase(repository),
    SendAssistantMessageUseCase(repository),
  );
}

AssistantResponse _response() {
  return const AssistantResponse(
    kind: 'NoResult',
    text: 'No grounded result.',
    language: 'en',
    correlationId: 'test-correlation',
    retryable: false,
    movies: [],
    clarificationChoices: [],
  );
}

class _FakeAssistantRepository implements AssistantRepository {
  _FakeAssistantRepository({required this.available});

  final bool available;
  final completer = Completer<AssistantResponse>();
  int sendCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AssistantResponse> sendMessage({
    required String message,
    required String locale,
    required List<AssistantChatMessage> history,
  }) {
    sendCount++;
    return completer.future;
  }
}
