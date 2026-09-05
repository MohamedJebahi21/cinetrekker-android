import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/models/media_models.dart';
import '../../watchlist/data/user_library_repository.dart';

class HomeFeedData {
  const HomeFeedData({
    required this.trendingDay,
    required this.trendingWeek,
    required this.nowPlaying,
    required this.continueWatching,
    required this.watchlistPreview,
    required this.genreSuggestions,
    required this.watched,
    required this.watchlist,
    this.genreName,
  });

  final List<TmdbMedia> trendingDay;
  final List<TmdbMedia> trendingWeek;
  final List<TmdbMedia> nowPlaying;
  final List<TmdbMedia> continueWatching;
  final List<TmdbMedia> watchlistPreview;
  final List<TmdbMedia> genreSuggestions;
  final List<UserMediaItem> watched;
  final List<UserMediaItem> watchlist;
  final String? genreName;
}

class HomeRepository {
  HomeRepository({
    required TmdbApiService tmdbApiService,
    required UserLibraryRepository userLibraryRepository,
  }) : _tmdbApiService = tmdbApiService,
       _userLibraryRepository = userLibraryRepository;

  final TmdbApiService _tmdbApiService;
  final UserLibraryRepository _userLibraryRepository;

  static const _genreNames = <int, String>{
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
    10759: 'Action & Adventure',
    10762: 'Kids',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
  };

  Future<HomeFeedData> load({required String language}) async {
    final libraryResults = await Future.wait([
      _userLibraryRepository.getWatched(),
      _userLibraryRepository.getWatchlist(),
      _userLibraryRepository.getFollowedShows(),
      _userLibraryRepository.getWatchedEpisodes(),
    ]);

    final watched = libraryResults[0] as List<UserMediaItem>;
    final watchlist = libraryResults[1] as List<UserMediaItem>;
    final followedShows = libraryResults[2] as List<FollowedShowItem>;
    final watchedEpisodes = libraryResults[3] as List<WatchedEpisodeItem>;

    final results = await Future.wait([
      _tmdbApiService.trending(language: language),
      _tmdbApiService.trending(language: language, timeWindow: 'week'),
      _tmdbApiService.nowPlayingMovies(language: language),
      if (watchlist.isNotEmpty)
        _tmdbApiService.details(
          mediaType: watchlist.first.mediaType,
          mediaId: watchlist.first.mediaId,
          language: language,
        ),
      if (watched.isNotEmpty)
        _tmdbApiService.details(
          mediaType: watched.first.mediaType,
          mediaId: watched.first.mediaId,
          language: language,
        ),
    ]);

    final trendingDay = results[0] as TmdbPagedResponse<TmdbMedia>;
    final trendingWeek = results[1] as TmdbPagedResponse<TmdbMedia>;
    final nowPlaying = results[2] as TmdbPagedResponse<TmdbMedia>;
    final watchlistDetails = watchlist.isNotEmpty
        ? results[3] as TmdbMediaDetails
        : null;
    final watchedDetails = watched.isNotEmpty
        ? results[watchlist.isNotEmpty ? 4 : 3] as TmdbMediaDetails
        : null;

    final genreId = watchedDetails?.genreIds.isNotEmpty == true
        ? watchedDetails!.genreIds.first
        : watchlistDetails?.genreIds.isNotEmpty == true
        ? watchlistDetails!.genreIds.first
        : 878;

    final genreName = _genreNames[genreId] ?? 'Sci-Fi & Action';

    final genreSuggestions = (await _tmdbApiService.discover(
      mediaType:
          watchedDetails?.mediaKind ?? watchlistDetails?.mediaKind ?? 'movie',
      language: language,
      params: <String, String>{
        'with_genres': genreId.toString(),
        'sort_by': 'popularity.desc',
      },
    )).results.take(12).toList(growable: false);

    final watchlistPreview = watchlist.isEmpty
        ? <TmdbMedia>[]
        : (await Future.wait(
            watchlist
                .take(2)
                .map(
                  (item) => _tmdbApiService.details(
                    mediaType: item.mediaType,
                    mediaId: item.mediaId,
                    language: language,
                  ),
                ),
          )).map(_mediaFromDetails).toList(growable: false);

    final continueWatching = await _loadContinueWatching(
      followedShows: followedShows,
      watchedEpisodes: watchedEpisodes,
      watched: watched,
      language: language,
    );

    return HomeFeedData(
      trendingDay: trendingDay.results,
      trendingWeek: trendingWeek.results,
      nowPlaying: nowPlaying.results,
      continueWatching: continueWatching,
      watchlistPreview: watchlistPreview,
      genreSuggestions: genreSuggestions,
      genreName: genreName,
      watched: watched,
      watchlist: watchlist,
    );
  }

  Future<List<TmdbMedia>> _loadContinueWatching({
    required List<FollowedShowItem> followedShows,
    required List<WatchedEpisodeItem> watchedEpisodes,
    required List<UserMediaItem> watched,
    required String language,
  }) async {
    final completedTvIds = watched
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

    // Only shows with recorded progress belong in Continue Watching.
    // Following a title is intentionally kept separate: it is a library
    // action, not evidence that the viewer has started the series.
    final candidateShowIds = <int>{};
    for (final show in followedShows) {
      if ((watchedCountByShowId[show.showId] ?? 0) > 0 ||
          show.lastWatchedSeason != null ||
          show.lastWatchedEpisode != null) {
        candidateShowIds.add(show.showId);
      }
    }
    for (final ep in watchedEpisodes) {
      candidateShowIds.add(ep.showId);
    }
    for (final item in watched) {
      if (item.mediaType == 'tv' && item.status != 'completed') {
        candidateShowIds.add(item.mediaId);
      }
    }
    candidateShowIds.removeAll(completedTvIds);

    if (candidateShowIds.isEmpty) {
      return const <TmdbMedia>[];
    }

    final sortedShowIds = candidateShowIds.toList()
      ..sort((a, b) {
        final aStamp =
            DateTime.tryParse(lastEpisodeByShowId[a]?.watchedAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bStamp =
            DateTime.tryParse(lastEpisodeByShowId[b]?.watchedAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bStamp.compareTo(aStamp);
      });

    return (await Future.wait(
      sortedShowIds
          .take(12)
          .map(
            (showId) => _tmdbApiService.details(
              mediaType: 'tv',
              mediaId: showId,
              language: language,
            ),
          ),
    )).map(_mediaFromDetails).toList(growable: false);
  }

  TmdbMedia _mediaFromDetails(TmdbMediaDetails details) {
    return TmdbMedia(
      id: details.id,
      title: details.title,
      name: details.name,
      originalTitle: details.originalTitle,
      originalName: details.originalName,
      overview: details.overview,
      posterPath: details.posterPath,
      profilePath: details.profilePath,
      backdropPath: details.backdropPath,
      releaseDate: details.releaseDate,
      firstAirDate: details.firstAirDate,
      voteAverage: details.voteAverage,
      voteCount: details.voteCount,
      popularity: details.popularity,
      genreIds: details.genreIds,
      mediaType: details.mediaKind,
      originalLanguage: details.originalLanguage,
      adult: details.adult,
    );
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    tmdbApiService: ref.read(tmdbApiServiceProvider),
    userLibraryRepository: ref.read(userLibraryRepositoryProvider),
  );
});
