import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/domain/entities/assistant_response.dart';
import 'package:movie_booking_app/domain/repositories/assistant_repository.dart';
import 'package:movie_booking_app/domain/usecases/assistant_usecases.dart';
import 'package:movie_booking_app/presentation/providers/assistant_provider.dart';
import 'package:movie_booking_app/presentation/screens/assistant/assistant_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('disabled assistant renders unavailable and retry semantics', (tester) async {
    final repository = _ScreenRepository(available: false);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Trợ lý phim hiện chưa khả dụng.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Thử lại'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('ready assistant sends message and renders grounded card', (tester) async {
    final repository = _ScreenRepository(available: true);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Recommend action');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Recommend action'), findsOneWidget);
    expect(find.text('Movie One'), findsOneWidget);
    expect(find.text('Matches action preference'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(AssistantRepository repository) {
  return ChangeNotifierProvider(
    create: (_) => AssistantProvider(
      GetAssistantAvailabilityUseCase(repository),
      SendAssistantMessageUseCase(repository),
    ),
    child: const MaterialApp(locale: Locale('en'), home: AssistantScreen()),
  );
}

class _ScreenRepository implements AssistantRepository {
  _ScreenRepository({required this.available});
  final bool available;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AssistantResponse> sendMessage({
    required String message,
    required String locale,
    required List<AssistantChatMessage> history,
  }) async {
    return AssistantResponse(
      kind: 'GroundedResult',
      text: 'A grounded answer',
      language: 'en',
      correlationId: 'test',
      retryable: false,
      movies: [
        AssistantMovieCard(
          id: 'movie-1',
          title: 'Movie One',
          description: 'Description',
          duration: 110,
          releaseDate: DateTime(2026, 8, 14),
          language: 'English',
          rating: 'T13',
          posterUrl: '',
          status: 'NowShowing',
          genres: const ['Action'],
          reason: 'Matches action preference',
        ),
      ],
      clarificationChoices: const [],
    );
  }
}
