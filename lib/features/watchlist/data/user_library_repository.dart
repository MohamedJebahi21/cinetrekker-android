import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/supabase_rest_api.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/models/media_models.dart';
import '../../../core/storage/local_media_list_storage.dart';

class UserLibraryRepository {
  UserLibraryRepository({
    required SupabaseRestApi supabaseRestApi,
    required LocalMediaListStorage localStorage,
    required String? userId,
  }) : _supabaseRestApi = supabaseRestApi,
       _localStorage = localStorage,
       _userId = userId;

  final SupabaseRestApi _supabaseRestApi;
  final LocalMediaListStorage _localStorage;
  final String? _userId;

  bool get _isSignedIn => _userId != null && _userId.isNotEmpty;

  Future<List<UserMediaItem>> getWatchlist() async {
    if (!_isSignedIn) {
      return _localStorage.readList(_guestWatchlistKey);
    }

    try {
      final rows = await _supabaseRestApi.selectRows(
        'user_watchlist',
        equals: <String, dynamic>{'user_id': _userId},
        orderBy: 'added_at',
        descending: true,
      );
      final items = rows
          .map(
            (row) => UserMediaItem(
              id: row['id']?.toString() ?? '',
              mediaId: (row['media_id'] as num?)?.toInt() ?? 0,
              mediaType: row['media_type'] as String? ?? 'movie',
              userId: row['user_id'] as String? ?? '',
              addedAt: row['added_at'] as String? ?? '',
            ),
          )
          .toList(growable: false);
      await _localStorage.writeList(_watchlistCacheKey, items);
      return items;
    } catch (_) {
      return _localStorage.readList(_watchlistCacheKey);
    }
  }

  Future<List<UserMediaItem>> getWatched() async {
    if (!_isSignedIn) {
      return _localStorage.readList(_guestWatchedKey);
    }

    try {
      final rows = await _supabaseRestApi.selectRows(
        'user_watched',
        equals: <String, dynamic>{'user_id': _userId},
        orderBy: 'watched_at',
        descending: true,
      );
      final items = rows
          .map(
            (row) => UserMediaItem(
              id: row['id']?.toString() ?? '',
              mediaId: (row['media_id'] as num?)?.toInt() ?? 0,
              mediaType: row['media_type'] as String? ?? 'movie',
              userId: row['user_id'] as String? ?? '',
              rating: (row['rating'] as num?)?.toDouble(),
              note: row['note'] as String?,
              status: row['status'] as String?,
              addedAt: row['watched_at'] as String? ?? '',
              watchedAt: row['watched_at'] as String?,
            ),
          )
          .toList(growable: false);
      await _localStorage.writeList(_watchedCacheKey, items);
      return items;
    } catch (_) {
      return _localStorage.readList(_watchedCacheKey);
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
    final item = UserMediaItem(
      id: '$mediaType-$mediaId',
      mediaId: mediaId,
      mediaType: mediaType,
      userId: _userId ?? 'guest',
      addedAt: DateTime.now().toIso8601String(),
      title: title,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
    );

    if (!_isSignedIn) {
      final next = [...await _localStorage.readList(_guestWatchlistKey)]
        ..removeWhere(
          (existing) =>
              existing.mediaId == mediaId && existing.mediaType == mediaType,
        )
        ..add(item);
      await _localStorage.writeList(_guestWatchlistKey, next);
      return;
    }

    await _supabaseRestApi.upsertRow('user_watchlist', <String, dynamic>{
      'user_id': _userId,
      'media_id': mediaId,
      'media_type': mediaType,
      'added_at': item.addedAt,
      if (title != null) 'title': title,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (releaseDate != null) 'release_date': releaseDate,
    }, onConflict: 'user_id,media_id,media_type');
  }

  Future<void> removeFromWatchlist({
    required int mediaId,
    required String mediaType,
  }) async {
    if (!_isSignedIn) {
      final next = [...await _localStorage.readList(_guestWatchlistKey)]
        ..removeWhere(
          (existing) =>
              existing.mediaId == mediaId && existing.mediaType == mediaType,
        );
      await _localStorage.writeList(_guestWatchlistKey, next);
      return;
    }

    await _supabaseRestApi.deleteRows(
      'user_watchlist',
      equals: <String, dynamic>{
        'user_id': _userId,
        'media_id': mediaId,
        'media_type': mediaType,
      },
    );
  }

  Future<void> addToWatched({
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
    final item = UserMediaItem(
      id: '$mediaType-$mediaId',
      mediaId: mediaId,
      mediaType: mediaType,
      userId: _userId ?? 'guest',
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

    if (!_isSignedIn) {
      final next = [...await _localStorage.readList(_guestWatchedKey)]
        ..removeWhere(
          (existing) =>
              existing.mediaId == mediaId && existing.mediaType == mediaType,
        )
        ..add(item);
      await _localStorage.writeList(_guestWatchedKey, next);
      return;
    }

    await _supabaseRestApi.upsertRow('user_watched', <String, dynamic>{
      'user_id': _userId,
      'media_id': mediaId,
      'media_type': mediaType,
      'rating': rating,
      'note': note,
      'status': status ?? 'completed',
      'watched_at': item.watchedAt,
      if (title != null) 'title': title,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (releaseDate != null) 'release_date': releaseDate,
    }, onConflict: 'user_id,media_id,media_type');
  }

  Future<void> updateWatched({
    required int mediaId,
    required String mediaType,
    double? rating,
    String? note,
    String? status,
  }) async {
    if (!_isSignedIn) {
      final list = await _localStorage.readList(_guestWatchedKey);
      final next = list
          .map(
            (existing) =>
                existing.mediaId == mediaId && existing.mediaType == mediaType
                ? UserMediaItem(
                    id: existing.id,
                    mediaId: existing.mediaId,
                    mediaType: existing.mediaType,
                    userId: existing.userId,
                    rating: rating ?? existing.rating,
                    note: note ?? existing.note,
                    status: status ?? existing.status,
                    addedAt: existing.addedAt,
                    watchedAt: existing.watchedAt,
                  )
                : existing,
          )
          .toList(growable: false);
      await _localStorage.writeList(_guestWatchedKey, next);
      return;
    }

    final updates = <String, dynamic>{
      if (rating != null) 'rating': rating,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
    };

    await _supabaseRestApi.upsertRow('user_watched', <String, dynamic>{
      'user_id': _userId,
      'media_id': mediaId,
      'media_type': mediaType,
      ...updates,
    }, onConflict: 'user_id,media_id,media_type');
  }

  Future<void> removeFromWatched({
    required int mediaId,
    required String mediaType,
  }) async {
    if (!_isSignedIn) {
      final next = [...await _localStorage.readList(_guestWatchedKey)]
        ..removeWhere(
          (existing) =>
              existing.mediaId == mediaId && existing.mediaType == mediaType,
        );
      await _localStorage.writeList(_guestWatchedKey, next);
      return;
    }

    await _supabaseRestApi.deleteRows(
      'user_watched',
      equals: <String, dynamic>{
        'user_id': _userId,
        'media_id': mediaId,
        'media_type': mediaType,
      },
    );
  }

  Future<List<FollowedShowItem>> getFollowedShows() async {
    if (!_isSignedIn) {
      return _localStorage.readFollowedShows(_guestFollowedShowsKey);
    }

    try {
      final rows = await _supabaseRestApi.selectRows(
        'followed_shows',
        equals: <String, dynamic>{'user_id': _userId},
        orderBy: 'followed_at',
        descending: true,
      );
      final items = rows.map(FollowedShowItem.fromJson).toList(growable: false);
      await _localStorage.writeFollowedShows(_guestFollowedShowsKey, items);
      return items;
    } catch (_) {
      return _localStorage.readFollowedShows(_guestFollowedShowsKey);
    }
  }

  Future<List<WatchedEpisodeItem>> getWatchedEpisodes({int? showId}) async {
    if (!_isSignedIn) {
      final list = await _localStorage.readWatchedEpisodes(
        _guestWatchedEpisodesKey,
      );
      if (showId != null) {
        return list.where((ep) => ep.showId == showId).toList(growable: false);
      }
      return list;
    }

    try {
      final rows = await _supabaseRestApi.selectRows(
        'watched_episodes',
        equals: <String, dynamic>{
          'user_id': _userId,
          if (showId != null) 'show_id': showId,
        },
        orderBy: 'watched_at',
        descending: true,
      );
      final items = rows
          .map(WatchedEpisodeItem.fromJson)
          .toList(growable: false);
      if (showId == null) {
        await _localStorage.writeWatchedEpisodes(
          _guestWatchedEpisodesKey,
          items,
        );
      }
      return items;
    } catch (_) {
      final list = await _localStorage.readWatchedEpisodes(
        _guestWatchedEpisodesKey,
      );
      if (showId != null) {
        return list.where((ep) => ep.showId == showId).toList(growable: false);
      }
      return list;
    }
  }

  Future<void> followShow({
    required int showId,
    required String showName,
    String? posterPath,
  }) async {
    final item = FollowedShowItem(
      showId: showId,
      showName: showName.trim(),
      posterPath: posterPath,
      userId: _userId ?? 'guest',
      followedAt: DateTime.now().toIso8601String(),
    );

    final current = await _localStorage.readFollowedShows(
      _guestFollowedShowsKey,
    );
    final next = [...current.where((s) => s.showId != showId), item];
    await _localStorage.writeFollowedShows(_guestFollowedShowsKey, next);

    if (!_isSignedIn) {
      return;
    }

    await _supabaseRestApi.upsertRow('followed_shows', <String, dynamic>{
      'user_id': _userId,
      'show_id': showId,
      if (showName.trim().isNotEmpty) 'show_name': showName.trim(),
      if (posterPath != null) 'poster_path': posterPath,
    }, onConflict: 'user_id,show_id');
  }

  Future<void> unfollowShow({required int showId}) async {
    final current = await _localStorage.readFollowedShows(
      _guestFollowedShowsKey,
    );
    final next = current
        .where((s) => s.showId != showId)
        .toList(growable: false);
    await _localStorage.writeFollowedShows(_guestFollowedShowsKey, next);

    if (!_isSignedIn) {
      return;
    }

    await _supabaseRestApi.deleteRows(
      'followed_shows',
      equals: <String, dynamic>{'user_id': _userId, 'show_id': showId},
    );
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
    final validatedEpisodeName = _normalizeEpisodeName(episodeName);
    final epItem = WatchedEpisodeItem(
      showId: showId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      episodeName: validatedEpisodeName,
      airDate: airDate,
      watchedAt: DateTime.now().toIso8601String(),
    );

    // Save to guest local storage
    final currentEps = await _localStorage.readWatchedEpisodes(
      _guestWatchedEpisodesKey,
    );
    final nextEps = [
      ...currentEps.where(
        (ep) =>
            !(ep.showId == showId &&
                ep.seasonNumber == seasonNumber &&
                ep.episodeNumber == episodeNumber),
      ),
      epItem,
    ];
    await _localStorage.writeWatchedEpisodes(_guestWatchedEpisodesKey, nextEps);

    // Also track in followed shows
    final currentShows = await _localStorage.readFollowedShows(
      _guestFollowedShowsKey,
    );
    final showItem = FollowedShowItem(
      showId: showId,
      userId: _userId ?? 'guest',
      showName:
          showName?.trim() ??
          currentShows.where((s) => s.showId == showId).firstOrNull?.showName,
      posterPath:
          posterPath ??
          currentShows.where((s) => s.showId == showId).firstOrNull?.posterPath,
      lastWatchedSeason: seasonNumber,
      lastWatchedEpisode: episodeNumber,
      followedAt: DateTime.now().toIso8601String(),
    );
    final nextShows = [
      ...currentShows.where((s) => s.showId != showId),
      showItem,
    ];
    await _localStorage.writeFollowedShows(_guestFollowedShowsKey, nextShows);

    // Also update guest watched with watching status
    await addToWatched(mediaId: showId, mediaType: 'tv', status: 'watching');

    if (!_isSignedIn) {
      return;
    }

    await _supabaseRestApi.upsertRow('watched_episodes', <String, dynamic>{
      'user_id': _userId,
      'show_id': showId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'episode_name': validatedEpisodeName,
      'air_date': airDate,
      'watched_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,show_id,season_number,episode_number');

    await _supabaseRestApi.upsertRow('followed_shows', <String, dynamic>{
      'user_id': _userId,
      'show_id': showId,
      if (showName != null && showName.trim().isNotEmpty)
        'show_name': showName.trim(),
      if (posterPath != null) 'poster_path': posterPath,
      'last_watched_season': seasonNumber,
      'last_watched_episode': episodeNumber,
    }, onConflict: 'user_id,show_id');

    await _supabaseRestApi.upsertRow('user_watched', <String, dynamic>{
      'user_id': _userId,
      'media_id': showId,
      'media_type': 'tv',
      'status': 'watching',
      'watched_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,media_id,media_type');
  }

  Future<void> markSeasonWatched({
    required int showId,
    required int seasonNumber,
    required List<Map<String, dynamic>> episodes,
    String? showName,
    String? posterPath,
  }) async {
    for (final ep in episodes) {
      final epNum = (ep['episode_number'] as num?)?.toInt() ?? 0;
      if (epNum > 0) {
        await markEpisodeWatched(
          showId: showId,
          seasonNumber: seasonNumber,
          episodeNumber: epNum,
          episodeName: ep['name'] as String?,
          airDate: ep['air_date'] as String?,
          showName: showName,
          posterPath: posterPath,
        );
      }
    }
  }

  Future<void> markAllSeasonsWatched({
    required int showId,
    required List<Map<String, dynamic>> episodes,
    String? showName,
    String? posterPath,
  }) async {
    for (final ep in episodes) {
      final sNum = (ep['season_number'] as num?)?.toInt() ?? 0;
      final epNum = (ep['episode_number'] as num?)?.toInt() ?? 0;
      if (sNum > 0 && epNum > 0) {
        await markEpisodeWatched(
          showId: showId,
          seasonNumber: sNum,
          episodeNumber: epNum,
          episodeName: ep['name'] as String?,
          airDate: ep['air_date'] as String?,
          showName: showName,
          posterPath: posterPath,
        );
      }
    }
  }

  Future<void> removeEpisodeWatched({
    required int showId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    final currentEps = await _localStorage.readWatchedEpisodes(
      _guestWatchedEpisodesKey,
    );
    final nextEps = currentEps
        .where(
          (ep) =>
              !(ep.showId == showId &&
                  ep.seasonNumber == seasonNumber &&
                  ep.episodeNumber == episodeNumber),
        )
        .toList(growable: false);
    await _localStorage.writeWatchedEpisodes(_guestWatchedEpisodesKey, nextEps);

    if (!_isSignedIn) {
      return;
    }

    await _supabaseRestApi.deleteRows(
      'watched_episodes',
      equals: <String, dynamic>{
        'user_id': _userId,
        'show_id': showId,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
      },
    );
  }

  Future<void> clearLocalData() async {
    await _localStorage.clear(_watchlistCacheKey);
    await _localStorage.clear(_watchedCacheKey);
    await _localStorage.clear(_guestWatchlistKey);
    await _localStorage.clear(_guestWatchedKey);
    await _localStorage.clear(_guestFollowedShowsKey);
    await _localStorage.clear(_guestWatchedEpisodesKey);
  }

  Future<void> deleteAccountData() async {
    if (!_isSignedIn) {
      return;
    }

    await _supabaseRestApi.deleteRows(
      'user_watchlist',
      equals: <String, dynamic>{'user_id': _userId},
    );
    await _supabaseRestApi.deleteRows(
      'user_watched',
      equals: <String, dynamic>{'user_id': _userId},
    );
    await _supabaseRestApi.deleteRows(
      'followed_shows',
      equals: <String, dynamic>{'user_id': _userId},
    );
    await _supabaseRestApi.deleteRows(
      'watched_episodes',
      equals: <String, dynamic>{'user_id': _userId},
    );
    await _supabaseRestApi.deleteRows(
      'new_episodes_cache',
      equals: <String, dynamic>{'user_id': _userId},
    );
    await clearLocalData();
  }

  static String? _normalizeEpisodeName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static const _watchlistCacheKey = 'cinetrekker_watchlist_cache';
  static const _watchedCacheKey = 'cinetrekker_watched_cache';
  static const _guestWatchlistKey = 'mywatch_watchlist';
  static const _guestWatchedKey = 'mywatch_watched';
  static const _guestFollowedShowsKey = 'cinetrekker_guest_followed_shows_v1';
  static const _guestWatchedEpisodesKey =
      'cinetrekker_guest_watched_episodes_v1';
}

final userLibraryRepositoryProvider = Provider<UserLibraryRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  return UserLibraryRepository(
    supabaseRestApi: ref.read(supabaseRestApiProvider),
    localStorage: LocalMediaListStorage(),
    userId: session?.user.id,
  );
});
