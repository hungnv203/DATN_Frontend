import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/data/models/assistant_response_model.dart';

void main() {
  test('maps grounded result and movie card contract', () {
    final model = AssistantResponseModel.fromJson({
      'kind': 'GroundedResult',
      'text': 'A grounded answer',
      'language': 'en',
      'correlationId': 'correlation-1',
      'retryable': false,
      'movies': [
        {
          'id': 'movie-1',
          'title': 'Movie One',
          'description': 'Description',
          'duration': 110,
          'releaseDate': '2026-08-14T00:00:00Z',
          'language': 'English',
          'rating': 'T13',
          'posterUrl': 'https://example.test/poster.jpg',
          'status': 'NowShowing',
          'genres': ['Action'],
          'reason': 'Matches action preference',
        },
      ],
      'clarificationChoices': [],
    });

    expect(model.kind, 'GroundedResult');
    expect(model.movies.single.title, 'Movie One');
    expect(model.movies.single.genres, ['Action']);
  });

  test('maps unavailable response without cards', () {
    final model = AssistantResponseModel.fromJson({
      'kind': 'Unavailable',
      'text': 'Unavailable',
      'language': 'en',
      'correlationId': 'correlation-2',
      'retryable': true,
    });

    expect(model.retryable, isTrue);
    expect(model.movies, isEmpty);
    expect(model.clarificationChoices, isEmpty);
  });
}
