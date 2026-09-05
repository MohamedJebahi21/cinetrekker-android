import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_messages.dart';
import '../../../core/models/media_models.dart';
import '../../watchlist/data/user_library_repository.dart';

class TvTrackingProgressItem {
  const TvTrackingProgressItem({
    required this.followedShow,
    required this.watchedEpisodeCount,
    required this.isCompleted,
    required this.lastEpisode,
  });

  final FollowedShowItem followedShow;
  final int watchedEpisodeCount;
  final bool isCompleted;
  final WatchedEpisodeItem? lastEpisode;
}

class TvTrackingState {
  const TvTrackingState({
    required this.continueWatching,
    required this.followedShows,
    required this.watchedEpisodes,
    required this.recentEpisodes,
    required this.isLoading,
    required this.error,
  });

  factory TvTrackingState.initial() {
    return const TvTrackingState(
      continueWatching: <TvTrackingProgressItem>[],
      followedShows: <FollowedShowItem>[],
      watchedEpisodes: <WatchedEpisodeItem>[],
      recentEpisodes: <WatchedEpisodeItem>[],
      isLoading: false,
      error: null,
    );
  }

  final List<TvTrackingProgressItem> continueWatching;
  final List<FollowedShowItem> followedShows;
  final List<WatchedEpisodeItem> watchedEpisodes;
  final List<WatchedEpisodeItem> recentEpisodes;
  final bool isLoading;
  final String? error;

  bool isFollowed(int showId) =>
      followedShows.any((show) => show.showId == showId);

  bool isEpisodeWatched({
    required int showId,
    required int seasonNumber,
    required int episodeNumber,
  }) => watchedEpisodes.any(
    (ep) =>
        ep.showId == showId &&
        ep.seasonNumber == seasonNumber &&
        ep.episodeNumber == episodeNumber,
  );

  TvTrackingState copyWith({
    List<TvTrackingProgressItem>? continueWatching,
    List<FollowedShowItem>? followedShows,
    List<WatchedEpisodeItem>? watchedEpisodes,
    List<WatchedEpisodeItem>? recentEpisodes,
    bool? isLoading,
    String? error,
  }) {
    return TvTrackingState(
      continueWatching: continueWatching ?? this.continueWatching,
      followedShows: followedShows ?? this.followedShows,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      recentEpisodes: recentEpisodes ?? this.recentEpisodes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final tvTrackingControllerProvider =
    NotifierProvider<TvTrackingController, TvTrackingState>(
      TvTrackingController.new,
    );

class TvTrackingController extends Notifier<TvTrackingState> {
  @override
  TvTrackingState build() {
    Future.microtask(load);
    return TvTrackingState.initial();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent &&
        state.watchedEpisodes.isEmpty &&
        state.followedShows.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final repository = ref.read(userLibraryRepositoryProvider);
      final results = await Future.wait([
        repository.getFollowedShows(),
        repository.getWatchedEpisodes(),
        repository.getWatched(),
      ]);

      final followedShows = results[0] as List<FollowedShowItem>;
      final watchedEpisodes = results[1] as List<WatchedEpisodeItem>;
      final watchedTitles = results[2] as List<UserMediaItem>;

      final completedTvIds = watchedTitles
          .where((item) => item.mediaType == 'tv' && item.status == 'completed')
          .map((item) => item.mediaId)
          .toSet();

      final watchedCountByShowId = <int, int>{};
      for (final episode in watchedEpisodes) {
        watchedCountByShowId.update(
          episode.showId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      final lastEpisodeByShowId = <int, WatchedEpisodeItem>{};
      for (final episode in watchedEpisodes) {
        final existing = lastEpisodeByShowId[episode.showId];
        if (existing == null) {
          lastEpisodeByShowId[episode.showId] = episode;
          continue;
        }

        final existingStamp =
            DateTime.tryParse(existing.watchedAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final nextStamp =
            DateTime.tryParse(episode.watchedAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (nextStamp.isAfter(existingStamp)) {
          lastEpisodeByShowId[episode.showId] = episode;
        }
      }

      final continueWatching = followedShows
          .where(
            (show) =>
                watchedCountByShowId[show.showId] != null &&
                watchedCountByShowId[show.showId]! > 0,
          )
          .where((show) => !completedTvIds.contains(show.showId))
          .map(
            (show) => TvTrackingProgressItem(
              followedShow: show,
              watchedEpisodeCount: watchedCountByShowId[show.showId] ?? 0,
              isCompleted: completedTvIds.contains(show.showId),
              lastEpisode: lastEpisodeByShowId[show.showId],
            ),
          )
          .toList(growable: false);

      final recentEpisodes = [...watchedEpisodes]
        ..sort((a, b) => (b.watchedAt ?? '').compareTo(a.watchedAt ?? ''));

      state = TvTrackingState(
        continueWatching: continueWatching,
        followedShows: followedShows,
        watchedEpisodes: watchedEpisodes,
        recentEpisodes: recentEpisodes,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> followShow({
    required int showId,
    required String showName,
    String? posterPath,
  }) async {
    final optimistic = FollowedShowItem(
      showId: showId,
      showName: showName,
      posterPath: posterPath,
      userId: 'user',
      followedAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(
      followedShows: [
        ...state.followedShows.where((s) => s.showId != showId),
        optimistic,
      ],
    );

    await ref
        .read(userLibraryRepositoryProvider)
        .followShow(showId: showId, showName: showName, posterPath: posterPath);
    await load(silent: true);
  }

  Future<void> unfollowShow({required int showId}) async {
    state = state.copyWith(
      followedShows: state.followedShows
          .where((s) => s.showId != showId)
          .toList(),
    );

    await ref.read(userLibraryRepositoryProvider).unfollowShow(showId: showId);
    await load(silent: true);
  }

  Future<void> markEpisodeWatched({
    required int showId,
    required int seasonNumber,
    required int episodeNumber,
    String? episodeName,
    String? airDate,
    String? showName,
    String? posterPath,
  }) async {
    final optimistic = WatchedEpisodeItem(
      showId: showId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      episodeName: episodeName,
      airDate: airDate,
      watchedAt: DateTime.now().toIso8601String(),
    );

    state = state.copyWith(
      watchedEpisodes: [
        ...state.watchedEpisodes.where(
          (ep) =>
              !(ep.showId == showId &&
                  ep.seasonNumber == seasonNumber &&
                  ep.episodeNumber == episodeNumber),
        ),
        optimistic,
      ],
    );

    await ref
        .read(userLibraryRepositoryProvider)
        .markEpisodeWatched(
          showId: showId,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          episodeName: episodeName,
          airDate: airDate,
          showName: showName,
          posterPath: posterPath,
        );
    await load(silent: true);
  }

  Future<void> markSeasonWatched({
    required int showId,
    required int seasonNumber,
    required List<TmdbEpisode> episodes,
    String? showName,
    String? posterPath,
  }) async {
    final now = DateTime.now().toIso8601String();
    final newItems = episodes
        .map(
          (ep) => WatchedEpisodeItem(
            showId: showId,
            seasonNumber: seasonNumber,
            episodeNumber: ep.episodeNumber,
            episodeName: ep.name,
            airDate: ep.airDate,
            watchedAt: now,
          ),
        )
        .toList();

    state = state.copyWith(
      watchedEpisodes: [
        ...state.watchedEpisodes.where(
          (ep) => !(ep.showId == showId && ep.seasonNumber == seasonNumber),
        ),
        ...newItems,
      ],
    );

    for (final ep in episodes) {
      await ref
          .read(userLibraryRepositoryProvider)
          .markEpisodeWatched(
            showId: showId,
            seasonNumber: seasonNumber,
            episodeNumber: ep.episodeNumber,
            episodeName: ep.name,
            airDate: ep.airDate,
            showName: showName,
            posterPath: posterPath,
          );
    }
    await load(silent: true);
  }

  Future<void> removeEpisodeWatched({
    required int showId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    state = state.copyWith(
      watchedEpisodes: state.watchedEpisodes
          .where(
            (ep) =>
                !(ep.showId == showId &&
                    ep.seasonNumber == seasonNumber &&
                    ep.episodeNumber == episodeNumber),
          )
          .toList(),
    );

    await ref
        .read(userLibraryRepositoryProvider)
        .removeEpisodeWatched(
          showId: showId,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
        );
    await load(silent: true);
  }

  Future<void> unmarkEpisodeWatched({
    required int showId,
    required int seasonNumber,
    required int episodeNumber,
  }) => removeEpisodeWatched(
    showId: showId,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber,
  );

  Future<void> markSeasonWatchedMaps({
    required int showId,
    required int seasonNumber,
    required List<Map<String, dynamic>> episodes,
    String? showName,
    String? posterPath,
  }) async {
    await ref
        .read(userLibraryRepositoryProvider)
        .markSeasonWatched(
          showId: showId,
          seasonNumber: seasonNumber,
          episodes: episodes,
          showName: showName,
          posterPath: posterPath,
        );
    await load(silent: true);
  }

  Future<void> markAllSeasonsWatched({
    required int showId,
    required List<Map<String, dynamic>> episodes,
    String? showName,
    String? posterPath,
  }) async {
    await ref
        .read(userLibraryRepositoryProvider)
        .markAllSeasonsWatched(
          showId: showId,
          episodes: episodes,
          showName: showName,
          posterPath: posterPath,
        );
    await load(silent: true);
  }
}
