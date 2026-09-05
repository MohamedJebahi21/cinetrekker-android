import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_messages.dart';
import '../../../core/models/media_models.dart';
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
  final bool isLoading;
  final String? error;

  YearInReviewState copyWith({
    int? totalWatched,
    int? watchlistCount,
    int? ratedCount,
    double? averageRating,
    String? topGenre,
    String? busiestDay,
    String? topRatedTitle,
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
      final results = await Future.wait(<Future<Object>>[
        repository.getWatchlist(),
        repository.getWatched(),
      ]);
      final watchlist = results[0] as List<UserMediaItem>;
      final watched = results[1] as List<UserMediaItem>;
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

      state = YearInReviewState(
        totalWatched: watched.length,
        watchlistCount: watchlist.length,
        ratedCount: rated.length,
        averageRating: average,
        topGenre: dominantCategory,
        busiestDay: watched.isNotEmpty
            ? 'Weekends (Peak Viewing)'
            : 'Not enough data',
        topRatedTitle: topRated == null
            ? 'Not enough data'
            : topRated.displayTitle,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }
}
