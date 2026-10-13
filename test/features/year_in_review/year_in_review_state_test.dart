import 'package:cinetrekker_android/features/year_in_review/presentation/year_in_review_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YearInReviewState', () {
    test('generates accurate share summary from state', () {
      const state = YearInReviewState(
        totalWatched: 42,
        watchlistCount: 15,
        ratedCount: 30,
        averageRating: 8.4,
        topGenre: 'Feature Films (35 logged)',
        busiestDay: 'Fridays (12 logged)',
        topRatedTitle: 'Interstellar',
        moviesCount: 35,
        tvShowsCount: 7,
        episodesCount: 88,
        isLoading: false,
        error: null,
      );

      final summary = state.toShareSummary();

      expect(summary, contains('My CineTrekker Year in Review'));
      expect(summary, contains('Total Titles Watched: 42 (35 movies, 7 TV series)'));
      expect(summary, contains('Episodes Logged: 88'));
      expect(summary, contains('Titles Rated: 30 (Avg: 8.4/10)'));
      expect(summary, contains('Top Rated: Interstellar'));
      expect(summary, contains('Busiest Viewing Day: Fridays (12 logged)'));
      expect(summary, contains('Watchlist Queue: 15 titles'));
    });
  });
}
