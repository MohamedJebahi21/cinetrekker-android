import 'package:cinetrekker_android/core/models/media_models.dart';
import 'package:cinetrekker_android/features/tv_tracking/presentation/tv_tracking_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TvTrackingState', () {
    test('initial state has empty tracking lists and no error', () {
      final state = TvTrackingState.initial();
      expect(state.continueWatching, isEmpty);
      expect(state.followedShows, isEmpty);
      expect(state.watchedEpisodes, isEmpty);
      expect(state.recentEpisodes, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('isFollowed returns true for followed shows', () {
      const show = FollowedShowItem(
        showId: 1399,
        showName: 'Game of Thrones',
        userId: 'user_1',
        followedAt: '2026-01-01T00:00:00Z',
      );

      final state = TvTrackingState.initial().copyWith(
        followedShows: [show],
      );

      expect(state.isFollowed(1399), isTrue);
      expect(state.isFollowed(9999), isFalse);
    });

    test('isEpisodeWatched accurately tracks individual episode', () {
      const ep = WatchedEpisodeItem(
        showId: 1399,
        seasonNumber: 1,
        episodeNumber: 1,
        episodeName: 'Winter Is Coming',
        watchedAt: '2026-01-01T00:00:00Z',
      );

      final state = TvTrackingState.initial().copyWith(
        watchedEpisodes: [ep],
      );

      expect(
        state.isEpisodeWatched(
          showId: 1399,
          seasonNumber: 1,
          episodeNumber: 1,
        ),
        isTrue,
      );
      expect(
        state.isEpisodeWatched(
          showId: 1399,
          seasonNumber: 1,
          episodeNumber: 2,
        ),
        isFalse,
      );
    });
  });
}
