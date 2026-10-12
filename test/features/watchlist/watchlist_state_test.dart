import 'package:cinetrekker_android/core/models/media_models.dart';
import 'package:cinetrekker_android/features/watchlist/presentation/watchlist_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchlistState', () {
    test('initial state is empty with no errors', () {
      final state = WatchlistState.initial();
      expect(state.watchlist, isEmpty);
      expect(state.watched, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('isInWatchlist and isWatched correctly identify items', () {
      const movieItem = UserMediaItem(
        id: 'movie-100',
        mediaId: 100,
        mediaType: 'movie',
        userId: 'test_user',
        addedAt: '2026-01-01T00:00:00Z',
        title: 'Inception',
      );

      const tvItem = UserMediaItem(
        id: 'tv-200',
        mediaId: 200,
        mediaType: 'tv',
        userId: 'test_user',
        addedAt: '2026-01-02T00:00:00Z',
        title: 'Breaking Bad',
      );

      final state = WatchlistState.initial().copyWith(
        watchlist: [movieItem],
        watched: [tvItem],
      );

      expect(state.isInWatchlist(100, 'movie'), isTrue);
      expect(state.isInWatchlist(200, 'tv'), isFalse);

      expect(state.isWatched(200, 'tv'), isTrue);
      expect(state.isWatched(100, 'movie'), isFalse);
    });
  });
}
