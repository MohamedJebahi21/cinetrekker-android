import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/media_models.dart';
import '../data/user_library_repository.dart';

class WatchlistState {
  const WatchlistState({
    required this.watchlist,
    required this.watched,
    required this.isLoading,
    required this.error,
  });

  factory WatchlistState.initial() {
    return const WatchlistState(
      watchlist: <UserMediaItem>[],
      watched: <UserMediaItem>[],
      isLoading: false,
      error: null,
    );
  }

  final List<UserMediaItem> watchlist;
  final List<UserMediaItem> watched;
  final bool isLoading;
  final String? error;

  bool isInWatchlist(int mediaId, String mediaType) => watchlist.any(
    (item) => item.mediaId == mediaId && item.mediaType == mediaType,
  );

  bool isWatched(int mediaId, String mediaType) => watched.any(
    (item) => item.mediaId == mediaId && item.mediaType == mediaType,
  );

  WatchlistState copyWith({
    List<UserMediaItem>? watchlist,
    List<UserMediaItem>? watched,
    bool? isLoading,
    String? error,
  }) {
    return WatchlistState(
      watchlist: watchlist ?? this.watchlist,
      watched: watched ?? this.watched,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final watchlistControllerProvider =
    NotifierProvider<WatchlistController, WatchlistState>(
      WatchlistController.new,
    );

class WatchlistController extends Notifier<WatchlistState> {
  @override
  WatchlistState build() {
    Future.microtask(load);
    return WatchlistState.initial();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent && state.watchlist.isEmpty && state.watched.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final repository = ref.read(userLibraryRepositoryProvider);
      final tmdbService = ref.read(tmdbApiServiceProvider);
      final language = ref.read(tmdbLanguageProvider);

      final results = await Future.wait([
        repository.getWatchlist(),
        repository.getWatched(),
      ]);

      final rawWatchlist = results[0];
      final rawWatched = results[1];

      // Enrich items with TMDB metadata in parallel if missing title or poster
      Future<UserMediaItem> enrichItem(UserMediaItem item) async {
        if (item.title != null && item.posterPath != null) return item;
        try {
          final details = await tmdbService.details(
            mediaType: item.mediaType,
            mediaId: item.mediaId,
            language: language,
          );
          return item.copyWith(
            title: details.displayTitle,
            posterPath: details.posterPath,
            backdropPath: details.backdropPath,
            voteAverage: details.voteAverage,
            releaseDate: details.releaseDate ?? details.firstAirDate,
          );
        } catch (_) {
          return item;
        }
      }

      final enrichedWatchlist = await Future.wait(rawWatchlist.map(enrichItem));
      final enrichedWatched = await Future.wait(rawWatched.map(enrichItem));

      state = WatchlistState(
        watchlist: enrichedWatchlist,
        watched: enrichedWatched,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> toggleWatchlist({
    required int mediaId,
    required String mediaType,
    String? title,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    String? releaseDate,
  }) async {
    final alreadyIn = state.isInWatchlist(mediaId, mediaType);
    if (alreadyIn) {
      await removeFromWatchlist(mediaId: mediaId, mediaType: mediaType);
    } else {
      await addToWatchlist(
        mediaId: mediaId,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
      );
    }
  }

  Future<void> addToWatchlist({
    required int mediaId,
    required String mediaType,
    String? title,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    String? releaseDate,
  }) async {
    final optimistic = UserMediaItem(
      id: '$mediaType-$mediaId',
      mediaId: mediaId,
      mediaType: mediaType,
      userId: 'user',
      addedAt: DateTime.now().toIso8601String(),
      title: title,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
    );

    state = state.copyWith(
      watchlist: [
        ...state.watchlist.where(
          (i) => !(i.mediaId == mediaId && i.mediaType == mediaType),
        ),
        optimistic,
      ],
    );

    await ref
        .read(userLibraryRepositoryProvider)
        .addToWatchlist(
          mediaId: mediaId,
          mediaType: mediaType,
          title: title,
          posterPath: posterPath,
          backdropPath: backdropPath,
          voteAverage: voteAverage,
          releaseDate: releaseDate,
        );
    await load(silent: true);
  }

  Future<void> removeFromWatchlist({
    required int mediaId,
    required String mediaType,
  }) async {
    state = state.copyWith(
      watchlist: state.watchlist
          .where((i) => !(i.mediaId == mediaId && i.mediaType == mediaType))
          .toList(),
    );

    await ref
        .read(userLibraryRepositoryProvider)
        .removeFromWatchlist(mediaId: mediaId, mediaType: mediaType);
    await load(silent: true);
  }

  Future<void> markWatched({
    required int mediaId,
    required String mediaType,
    double? rating,
    String? note,
    String? status,
    String? title,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    String? releaseDate,
  }) async {
    final optimistic = UserMediaItem(
      id: '$mediaType-$mediaId',
      mediaId: mediaId,
      mediaType: mediaType,
      userId: 'user',
      rating: rating,
      note: note,
      status: status ?? 'completed',
      addedAt: DateTime.now().toIso8601String(),
      watchedAt: DateTime.now().toIso8601String(),
      title: title,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
    );

    state = state.copyWith(
      watched: [
        ...state.watched.where(
          (i) => !(i.mediaId == mediaId && i.mediaType == mediaType),
        ),
        optimistic,
      ],
    );

    await ref
        .read(userLibraryRepositoryProvider)
        .addToWatched(
          mediaId: mediaId,
          mediaType: mediaType,
          rating: rating,
          note: note,
          status: status,
          title: title,
          posterPath: posterPath,
          backdropPath: backdropPath,
          voteAverage: voteAverage,
          releaseDate: releaseDate,
        );
    await load(silent: true);
  }

  Future<void> removeFromWatched({
    required int mediaId,
    required String mediaType,
  }) async {
    state = state.copyWith(
      watched: state.watched
          .where((i) => !(i.mediaId == mediaId && i.mediaType == mediaType))
          .toList(),
    );

    await ref
        .read(userLibraryRepositoryProvider)
        .removeFromWatched(mediaId: mediaId, mediaType: mediaType);
    await load(silent: true);
  }
}
