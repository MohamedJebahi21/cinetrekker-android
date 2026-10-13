import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_messages.dart';
import '../../../core/models/media_models.dart';
import '../../tv_tracking/domain/tv_tracking_models.dart';
import '../../watchlist/data/user_library_repository.dart';

class YearInReviewState {
  const YearInReviewState({
    required this.totalWatched,
    required this.watchlistCount,
    required this.ratedCount,
    required this.averageRating,
    required this.topGenre,
    required this.busiestDay,
    required this.topRatedTitle,
    required this.moviesCount,
    required this.tvShowsCount,
    required this.episodesCount,
    required this.isLoading,
    required this.error,
  });

  factory YearInReviewState.initial() => const YearInReviewState(
    totalWatched: 0,
    watchlistCount: 0,
    ratedCount: 0,
    averageRating: 0,
    topGenre: 'Not enough data',
    busiestDay: 'Not enough data',
    topRatedTitle: 'Not enough data',
    moviesCount: 0,
    tvShowsCount: 0,
    episodesCount: 0,
    isLoading: false,
    error: null,
  );

  final int totalWatched;
  final int watchlistCount;
  final int ratedCount;
  final double averageRating;
  final String topGenre;
  final String busiestDay;
  final String topRatedTitle;
  final int moviesCount;
  final int tvShowsCount;
  final int episodesCount;
  final bool isLoading;
  final String? error;

  String toShareSummary() {
    final buffer = StringBuffer();
    buffer.writeln('🎬 My CineTrekker Year in Review');
    buffer.writeln('• Total Titles Watched: $totalWatched ($moviesCount movies, $tvShowsCount TV series)');
    if (episodesCount > 0) {
      buffer.writeln('• Episodes Logged: $episodesCount');
    }
    if (ratedCount > 0) {
      buffer.writeln('• Titles Rated: $ratedCount (Avg: ${averageRating.toStringAsFixed(1)}/10)');
    }
    if (topRatedTitle != 'Not enough data') {
      buffer.writeln('• Top Rated: $topRatedTitle');
    }
    buffer.writeln('• Busiest Viewing Day: $busiestDay');
    buffer.writeln('• Watchlist Queue: $watchlistCount titles');
    buffer.writeln('\nTracked with CineTrekker for Android');
    return buffer.toString();
  }

  YearInReviewState copyWith({
    int? totalWatched,
    int? watchlistCount,
    int? ratedCount,
    double? averageRating,
    String? topGenre,
    String? busiestDay,
    String? topRatedTitle,
    int? moviesCount,
    int? tvShowsCount,
    int? episodesCount,
    bool? isLoading,
    String? error,
  }) {
    return YearInReviewState(
      totalWatched: totalWatched ?? this.totalWatched,
      watchlistCount: watchlistCount ?? this.watchlistCount,
      ratedCount: ratedCount ?? this.ratedCount,
      averageRating: averageRating ?? this.averageRating,
      topGenre: topGenre ?? this.topGenre,
      busiestDay: busiestDay ?? this.busiestDay,
      topRatedTitle: topRatedTitle ?? this.topRatedTitle,
      moviesCount: moviesCount ?? this.moviesCount,
      tvShowsCount: tvShowsCount ?? this.tvShowsCount,
      episodesCount: episodesCount ?? this.episodesCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final yearInReviewControllerProvider =
    NotifierProvider<YearInReviewController, YearInReviewState>(
      YearInReviewController.new,
    );

class YearInReviewController extends Notifier<YearInReviewState> {
  @override
  YearInReviewState build() => YearInReviewState.initial();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(userLibraryRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.getWatchlist(),
        repository.getWatched(),
        repository.getWatchedEpisodes(),
        repository.getFollowedShows(),
      ]);
      final watchlist = results[0] as List<UserMediaItem>;
      final watched = results[1] as List<UserMediaItem>;
      final episodes = results[2] as List<WatchedEpisodeRecord>;
      final followedShows = results[3] as List<FollowedShowRecord>;

      final rated = watched.where((item) => item.rating != null).toList();
      final ratings = rated
          .map((item) => item.rating)
          .whereType<double>()
          .toList();
      final average = ratings.isEmpty
          ? 0.0
          : ratings.reduce((left, right) => left + right) / ratings.length;
      final topRated = rated.isEmpty
          ? null
          : rated.reduce(
              (left, right) =>
                  (left.rating ?? double.negativeInfinity) >=
                          (right.rating ?? double.negativeInfinity)
                      ? left
                      : right,
            );

      final movieCount = watched.where((i) => i.mediaType == 'movie').length;
      final tvCount = watched.where((i) => i.mediaType == 'tv').length;
      final dominantCategory = movieCount >= tvCount
          ? (movieCount > 0
              ? 'Feature Films ($movieCount logged)'
              : 'Cinema Discovery')
          : 'TV Series ($tvCount logged)';

      // Calculate actual busiest day of the week from real timestamps
      String busiestDayText = 'Not enough data';
      final dayCounts = <int, int>{};
      for (final item in watched) {
        if (item.watchedAt != null) {
          final dt = DateTime.tryParse(item.watchedAt!);
          if (dt != null) {
            dayCounts[dt.weekday] = (dayCounts[dt.weekday] ?? 0) + 1;
          }
        }
      }
      for (final ep in episodes) {
        if (ep.watchedAt != null) {
          final dt = DateTime.tryParse(ep.watchedAt!);
          if (dt != null) {
            dayCounts[dt.weekday] = (dayCounts[dt.weekday] ?? 0) + 1;
          }
        }
      }

      if (dayCounts.isNotEmpty) {
        const dayNames = [
          'Mondays',
          'Tuesdays',
          'Wednesdays',
          'Thursdays',
          'Fridays',
          'Saturdays',
          'Sundays',
        ];
        var bestDay = 1;
        var maxCount = -1;
        dayCounts.forEach((day, count) {
          if (count > maxCount) {
            maxCount = count;
            bestDay = day;
          }
        });
        busiestDayText = '${dayNames[bestDay - 1]} ($maxCount logged)';
      }

      state = YearInReviewState(
        totalWatched: watched.length,
        watchlistCount: watchlist.length,
        ratedCount: rated.length,
        averageRating: average,
        topGenre: dominantCategory,
        busiestDay: busiestDayText,
        topRatedTitle: topRated == null
            ? 'Not enough data'
            : topRated.displayTitle,
        moviesCount: movieCount,
        tvShowsCount: tvCount > 0 ? tvCount : followedShows.length,
        episodesCount: episodes.length,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }
}
