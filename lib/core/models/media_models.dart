class TmdbPagedResponse<T> {
  const TmdbPagedResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  final int page;
  final List<T> results;
  final int totalPages;
  final int totalResults;

  factory TmdbPagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawResults = json['results'];
    return TmdbPagedResponse<T>(
      page: (json['page'] as num?)?.toInt() ?? 1,
      results: rawResults is List
          ? rawResults
                .whereType<Map>()
                .map((item) => fromJson(item.cast<String, dynamic>()))
                .toList(growable: false)
          : <T>[],
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      totalResults: (json['total_results'] as num?)?.toInt() ?? 0,
    );
  }
}

class TmdbMedia {
  const TmdbMedia({
    required this.id,
    this.mediaType,
    this.mediaKind = 'movie',
    this.title,
    this.name,
    this.originalTitle,
    this.originalName,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.profilePath,
    this.releaseDate,
    this.firstAirDate,
    this.voteAverage = 0,
    this.voteCount = 0,
    this.popularity = 0,
    this.adult = false,
    this.originalLanguage,
    this.genreIds = const <int>[],
  });

  final int id;
  final String? mediaType;
  final String mediaKind;
  final String? title;
  final String? name;
  final String? originalTitle;
  final String? originalName;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? profilePath;
  final String? releaseDate;
  final String? firstAirDate;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final bool adult;
  final String? originalLanguage;
  final List<int> genreIds;

  String get displayTitle =>
      (title ?? name ?? originalTitle ?? originalName ?? 'Untitled').trim();
  String? get imagePath => posterPath ?? profilePath;
  int? get mediaId => id;
  int? get year {
    final value = releaseDate ?? firstAirDate;
    if (value == null || value.length < 4) return null;
    return int.tryParse(value.substring(0, 4));
  }

  factory TmdbMedia.fromJson(Map<String, dynamic> json) {
    final rawGenreIds = json['genre_ids'];
    return TmdbMedia(
      id: (json['id'] as num?)?.toInt() ?? 0,
      mediaType: json['media_type'] as String?,
      mediaKind:
          (json['media_type'] as String?) ??
          (json['name'] != null ? 'tv' : 'movie'),
      title: json['title'] as String?,
      name: json['name'] as String?,
      originalTitle: json['original_title'] as String?,
      originalName: json['original_name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      profilePath: json['profile_path'] as String?,
      releaseDate: json['release_date'] as String?,
      firstAirDate: json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      adult: json['adult'] as bool? ?? false,
      originalLanguage: json['original_language'] as String?,
      genreIds: rawGenreIds is List
          ? rawGenreIds
                .whereType<num>()
                .map((value) => value.toInt())
                .toList(growable: false)
          : const <int>[],
    );
  }
}

class TmdbGenre {
  const TmdbGenre({required this.id, required this.name});
  final int id;
  final String name;
  factory TmdbGenre.fromJson(Map<String, dynamic> json) => TmdbGenre(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? 'Unknown genre',
  );
}

class TmdbCastMember {
  const TmdbCastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    this.order = 0,
  });

  final int id;
  final String name;
  final String? character;
  final String? profilePath;
  final int order;

  factory TmdbCastMember.fromJson(Map<String, dynamic> json) => TmdbCastMember(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? 'Unknown actor',
    character: json['character'] as String?,
    profilePath: json['profile_path'] as String?,
    order: (json['order'] as num?)?.toInt() ?? 0,
  );
}

class TmdbVideo {
  const TmdbVideo({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    this.type,
  });

  final String id;
  final String key;
  final String name;
  final String site;
  final String? type;

  factory TmdbVideo.fromJson(Map<String, dynamic> json) => TmdbVideo(
    id: json['id'] as String? ?? '',
    key: json['key'] as String? ?? '',
    name: json['name'] as String? ?? '',
    site: json['site'] as String? ?? '',
    type: json['type'] as String?,
  );
}

class TmdbWatchProvider {
  const TmdbWatchProvider({
    required this.providerId,
    required this.providerName,
    this.logoPath,
  });

  final int providerId;
  final String providerName;
  final String? logoPath;

  factory TmdbWatchProvider.fromJson(Map<String, dynamic> json) =>
      TmdbWatchProvider(
        providerId: (json['provider_id'] as num?)?.toInt() ?? 0,
        providerName: json['provider_name'] as String? ?? 'Provider',
        logoPath: json['logo_path'] as String?,
      );
}

class TmdbWatchProvidersGroup {
  const TmdbWatchProvidersGroup({
    this.link,
    this.flatrate = const <TmdbWatchProvider>[],
    this.rent = const <TmdbWatchProvider>[],
    this.buy = const <TmdbWatchProvider>[],
  });

  final String? link;
  final List<TmdbWatchProvider> flatrate;
  final List<TmdbWatchProvider> rent;
  final List<TmdbWatchProvider> buy;

  bool get isEmpty => flatrate.isEmpty && rent.isEmpty && buy.isEmpty;

  factory TmdbWatchProvidersGroup.fromJson(Map<String, dynamic> json) {
    List<TmdbWatchProvider> parseList(dynamic list) {
      if (list is! List) return const <TmdbWatchProvider>[];
      return list
          .whereType<Map>()
          .map(
            (item) => TmdbWatchProvider.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false);
    }

    return TmdbWatchProvidersGroup(
      link: json['link'] as String?,
      flatrate: parseList(json['flatrate']),
      rent: parseList(json['rent']),
      buy: parseList(json['buy']),
    );
  }
}

class TmdbSeasonSummary {
  const TmdbSeasonSummary({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.episodeCount = 0,
    this.posterPath,
    this.overview,
  });

  final int id;
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? posterPath;
  final String? overview;

  factory TmdbSeasonSummary.fromJson(Map<String, dynamic> json) =>
      TmdbSeasonSummary(
        id: (json['id'] as num?)?.toInt() ?? 0,
        seasonNumber: (json['season_number'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? 'Season',
        episodeCount: (json['episode_count'] as num?)?.toInt() ?? 0,
        posterPath: json['poster_path'] as String?,
        overview: json['overview'] as String?,
      );
}

class TmdbEpisode {
  const TmdbEpisode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.voteAverage = 0,
    this.runtime,
  });

  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final double voteAverage;
  final int? runtime;

  factory TmdbEpisode.fromJson(Map<String, dynamic> json) => TmdbEpisode(
    id: (json['id'] as num?)?.toInt() ?? 0,
    episodeNumber: (json['episode_number'] as num?)?.toInt() ?? 1,
    seasonNumber: (json['season_number'] as num?)?.toInt() ?? 1,
    name: json['name'] as String? ?? 'Episode',
    overview: json['overview'] as String?,
    stillPath: json['still_path'] as String?,
    airDate: json['air_date'] as String?,
    voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
    runtime: (json['runtime'] as num?)?.toInt(),
  );
}

class TmdbSeasonDetails {
  const TmdbSeasonDetails({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.episodes = const <TmdbEpisode>[],
  });

  final int id;
  final int seasonNumber;
  final String name;
  final String? overview;
  final List<TmdbEpisode> episodes;

  factory TmdbSeasonDetails.fromJson(Map<String, dynamic> json) {
    final rawEpisodes = json['episodes'];
    final episodeList = rawEpisodes is List
        ? rawEpisodes
              .whereType<Map>()
              .map((e) => TmdbEpisode.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false)
        : const <TmdbEpisode>[];

    return TmdbSeasonDetails(
      id: (json['id'] as num?)?.toInt() ?? 0,
      seasonNumber: (json['season_number'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? 'Season',
      overview: json['overview'] as String?,
      episodes: episodeList,
    );
  }
}

class TmdbMediaDetails extends TmdbMedia {
  const TmdbMediaDetails({
    required super.id,
    super.mediaType,
    super.mediaKind,
    super.title,
    super.name,
    super.originalTitle,
    super.originalName,
    super.overview,
    super.posterPath,
    super.backdropPath,
    super.releaseDate,
    super.firstAirDate,
    super.voteAverage,
    super.voteCount,
    super.popularity,
    super.adult,
    super.originalLanguage,
    super.genreIds,
    this.runtime,
    this.status,
    this.tagline,
    this.certification,
    this.genres = const <TmdbGenre>[],
    this.cast = const <TmdbCastMember>[],
    this.videos = const <TmdbVideo>[],
    this.seasons = const <TmdbSeasonSummary>[],
    this.watchProviders,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.imdbId,
  });

  final int? runtime;
  final String? status;
  final String? tagline;
  final String? certification;
  final String? imdbId;
  final List<TmdbGenre> genres;
  final List<TmdbCastMember> cast;
  final List<TmdbVideo> videos;
  final List<TmdbSeasonSummary> seasons;
  final TmdbWatchProvidersGroup? watchProviders;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;

  factory TmdbMediaDetails.fromJson(Map<String, dynamic> json) {
    final base = TmdbMedia.fromJson(json);

    // Extract cast
    final credits = json['credits'];
    final rawCast = credits is Map ? credits['cast'] : null;
    final castList = rawCast is List
        ? rawCast
              .whereType<Map>()
              .map(
                (item) => TmdbCastMember.fromJson(item.cast<String, dynamic>()),
              )
              .toList(growable: false)
        : const <TmdbCastMember>[];

    // Extract videos
    final videosObj = json['videos'];
    final rawVideos = videosObj is Map ? videosObj['results'] : null;
    final videosList = rawVideos is List
        ? rawVideos
              .whereType<Map>()
              .map((item) => TmdbVideo.fromJson(item.cast<String, dynamic>()))
              .toList(growable: false)
        : const <TmdbVideo>[];

    // Extract seasons
    final rawSeasons = json['seasons'];
    final seasonsList = rawSeasons is List
        ? rawSeasons
              .whereType<Map>()
              .map((s) => TmdbSeasonSummary.fromJson(s.cast<String, dynamic>()))
              .where((s) => s.seasonNumber > 0)
              .toList(growable: false)
        : const <TmdbSeasonSummary>[];

    // Extract watch providers
    TmdbWatchProvidersGroup? providers;
    final wpObj = json['watch/providers'] ?? json['watch_providers'];
    if (wpObj is Map && wpObj['results'] is Map) {
      final results = wpObj['results'] as Map;
      final us = results['US'] ?? results['GB'] ?? results.values.firstOrNull;
      if (us is Map) {
        providers = TmdbWatchProvidersGroup.fromJson(
          us.cast<String, dynamic>(),
        );
      }
    }

    // Extract certification / rating tag
    String? cert;
    if (json['release_dates'] != null) {
      final results = json['release_dates']['results'];
      if (results is List) {
        for (final r in results) {
          if (r is Map && r['iso_3166_1'] == 'US') {
            final dates = r['release_dates'];
            if (dates is List) {
              for (final d in dates) {
                final c = d['certification'] as String?;
                if (c != null && c.isNotEmpty) {
                  cert = c;
                  break;
                }
              }
            }
          }
        }
      }
    } else if (json['content_ratings'] != null) {
      final results = json['content_ratings']['results'];
      if (results is List) {
        for (final r in results) {
          if (r is Map && r['iso_3166_1'] == 'US') {
            final rating = r['rating'] as String?;
            if (rating != null && rating.isNotEmpty) {
              cert = rating;
              break;
            }
          }
        }
      }
    }

    // Extract IMDb ID
    final rawExt = json['external_ids'];
    final imdbId = json['imdb_id'] as String? ??
        (rawExt is Map ? rawExt['imdb_id'] as String? : null);

    return TmdbMediaDetails(
      id: base.id,
      mediaType: base.mediaType,
      mediaKind: base.mediaKind,
      title: base.title,
      name: base.name,
      originalTitle: base.originalTitle,
      originalName: base.originalName,
      overview: base.overview,
      posterPath: base.posterPath,
      backdropPath: base.backdropPath,
      releaseDate: base.releaseDate,
      firstAirDate: base.firstAirDate,
      voteAverage: base.voteAverage,
      voteCount: base.voteCount,
      popularity: base.popularity,
      adult: base.adult,
      originalLanguage: base.originalLanguage,
      genreIds: base.genreIds,
      runtime: (json['runtime'] as num?)?.toInt(),
      status: json['status'] as String?,
      tagline: json['tagline'] as String?,
      certification: cert,
      numberOfSeasons: (json['number_of_seasons'] as num?)?.toInt(),
      numberOfEpisodes: (json['number_of_episodes'] as num?)?.toInt(),
      genres: json['genres'] is List
          ? (json['genres'] as List)
                .whereType<Map>()
                .map((item) => TmdbGenre.fromJson(item.cast<String, dynamic>()))
                .toList(growable: false)
          : const <TmdbGenre>[],
      cast: castList,
      videos: videosList,
      seasons: seasonsList,
      watchProviders: providers,
      imdbId: imdbId,
    );
  }
}

class TmdbPersonDetails {
  const TmdbPersonDetails({
    required this.id,
    this.name,
    this.biography,
    this.birthday,
    this.deathday,
    this.knownForDepartment,
    this.popularity = 0,
    this.profilePath,
    this.combinedCredits = const <TmdbMedia>[],
  });

  final int id;
  final String? name;
  final String? biography;
  final String? birthday;
  final String? deathday;
  final String? knownForDepartment;
  final double popularity;
  final String? profilePath;
  final List<TmdbMedia> combinedCredits;

  String get displayTitle => name ?? 'Unknown person';
  String? get imagePath => profilePath;
  String? get bio => biography;

  factory TmdbPersonDetails.fromJson(Map<String, dynamic> json) {
    final credits = json['combined_credits'];
    final cast = credits is Map ? credits['cast'] : null;
    return TmdbPersonDetails(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String?,
      biography: json['biography'] as String?,
      birthday: json['birthday'] as String?,
      deathday: json['deathday'] as String?,
      knownForDepartment: json['known_for_department'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      profilePath: json['profile_path'] as String?,
      combinedCredits: cast is List
          ? cast
                .whereType<Map>()
                .map((item) => TmdbMedia.fromJson(item.cast<String, dynamic>()))
                .toList(growable: false)
          : const <TmdbMedia>[],
    );
  }
}

class UserMediaItem {
  const UserMediaItem({
    required this.id,
    required this.mediaId,
    required this.mediaType,
    required this.userId,
    required this.addedAt,
    this.rating,
    this.note,
    this.status,
    this.watchedAt,
    this.title,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.releaseDate,
  });

  final String id;
  final int mediaId;
  final String mediaType;
  final String userId;
  final double? rating;
  final String? note;
  final String? status;
  final String addedAt;
  final String? watchedAt;
  final String? title;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final String? releaseDate;

  String get displayTitle => (title != null && title!.trim().isNotEmpty)
      ? title!
      : '${mediaType == 'tv' ? 'TV Series' : 'Movie'} #$mediaId';

  String? get year => releaseDate != null && releaseDate!.length >= 4
      ? releaseDate!.substring(0, 4)
      : null;

  UserMediaItem copyWith({
    String? id,
    int? mediaId,
    String? mediaType,
    String? userId,
    double? rating,
    String? note,
    String? status,
    String? addedAt,
    String? watchedAt,
    String? title,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    String? releaseDate,
  }) {
    return UserMediaItem(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      userId: userId ?? this.userId,
      addedAt: addedAt ?? this.addedAt,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      status: status ?? this.status,
      watchedAt: watchedAt ?? this.watchedAt,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'media_id': mediaId,
    'media_type': mediaType,
    'user_id': userId,
    'rating': rating,
    'note': note,
    'status': status,
    'added_at': addedAt,
    'watched_at': watchedAt,
    'title': title,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'vote_average': voteAverage,
    'release_date': releaseDate,
  };

  factory UserMediaItem.fromJson(Map<String, dynamic> json) => UserMediaItem(
    id: json['id']?.toString() ?? '',
    mediaId: (json['media_id'] as num?)?.toInt() ?? 0,
    mediaType: json['media_type'] as String? ?? 'movie',
    userId: json['user_id'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble(),
    note: json['note'] as String?,
    status: json['status'] as String?,
    addedAt: json['added_at'] as String? ?? json['watched_at'] as String? ?? '',
    watchedAt: json['watched_at'] as String?,
    title:
        json['title'] as String? ??
        json['show_name'] as String? ??
        json['name'] as String?,
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    voteAverage: (json['vote_average'] as num?)?.toDouble(),
    releaseDate:
        json['release_date'] as String? ?? json['first_air_date'] as String?,
  );
}

class FollowedShowItem {
  const FollowedShowItem({
    required this.showId,
    required this.userId,
    this.showName,
    this.posterPath,
    this.followedAt,
    this.lastWatchedSeason,
    this.lastWatchedEpisode,
    this.nextAirDate,
    this.nextEpisodeName,
  });

  final int showId;
  final String userId;
  final String? showName;
  final String? posterPath;
  final String? followedAt;
  final int? lastWatchedSeason;
  final int? lastWatchedEpisode;
  /// ISO-8601 date string for the next episode air date (e.g. "2025-10-05").
  final String? nextAirDate;
  /// Name / label of the next episode if known.
  final String? nextEpisodeName;

  /// Returns true if nextAirDate is within the next [days] days (inclusive).
  bool isAiringSoon({int days = 7}) {
    if (nextAirDate == null) return false;
    final air = DateTime.tryParse(nextAirDate!);
    if (air == null) return false;
    final now = DateTime.now();
    final diff = air.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff >= 0 && diff <= days;
  }

  /// Days until next air date; negative if already aired.
  int? daysUntilAir() {
    if (nextAirDate == null) return null;
    final air = DateTime.tryParse(nextAirDate!);
    if (air == null) return null;
    final now = DateTime.now();
    return air.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'show_id': showId,
    'user_id': userId,
    'show_name': showName,
    'poster_path': posterPath,
    'followed_at': followedAt,
    'last_watched_season': lastWatchedSeason,
    'last_watched_episode': lastWatchedEpisode,
    'next_air_date': nextAirDate,
    'next_episode_name': nextEpisodeName,
  };

  factory FollowedShowItem.fromJson(Map<String, dynamic> json) =>
      FollowedShowItem(
        showId: (json['show_id'] as num?)?.toInt() ?? 0,
        userId: json['user_id'] as String? ?? '',
        showName: json['show_name'] as String?,
        posterPath: json['poster_path'] as String?,
        followedAt: json['followed_at'] as String?,
        lastWatchedSeason: (json['last_watched_season'] as num?)?.toInt(),
        lastWatchedEpisode: (json['last_watched_episode'] as num?)?.toInt(),
        nextAirDate: json['next_air_date'] as String?,
        nextEpisodeName: json['next_episode_name'] as String?,
      );
}

class WatchedEpisodeItem {
  const WatchedEpisodeItem({
    required this.showId,
    required this.seasonNumber,
    required this.episodeNumber,
    this.episodeName,
    this.airDate,
    this.watchedAt,
  });

  final int showId;
  final int seasonNumber;
  final int episodeNumber;
  final String? episodeName;
  final String? airDate;
  final String? watchedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'show_id': showId,
    'season_number': seasonNumber,
    'episode_number': episodeNumber,
    'episode_name': episodeName,
    'air_date': airDate,
    'watched_at': watchedAt,
  };

  factory WatchedEpisodeItem.fromJson(Map<String, dynamic> json) =>
      WatchedEpisodeItem(
        showId: (json['show_id'] as num?)?.toInt() ?? 0,
        seasonNumber: (json['season_number'] as num?)?.toInt() ?? 0,
        episodeNumber: (json['episode_number'] as num?)?.toInt() ?? 0,
        episodeName: json['episode_name'] as String?,
        airDate: json['air_date'] as String?,
        watchedAt: json['watched_at'] as String?,
      );
}

class EnrichedRatings {
  const EnrichedRatings({
    this.imdbRating,
    this.imdbVotes,
    this.rottenTomatoes,
    this.metascore,
    this.awards,
    this.boxOffice,
  });

  final String? imdbRating;
  final String? imdbVotes;
  final String? rottenTomatoes;
  final String? metascore;
  final String? awards;
  final String? boxOffice;

  bool get hasAnyRating =>
      (rottenTomatoes != null && rottenTomatoes!.isNotEmpty) ||
      (metascore != null && metascore!.isNotEmpty) ||
      (imdbRating != null && imdbRating!.isNotEmpty);

  factory EnrichedRatings.fromJson(Map<String, dynamic> json) => EnrichedRatings(
    imdbRating: json['imdbRating'] as String?,
    imdbVotes: json['imdbVotes'] as String?,
    rottenTomatoes: json['rottenTomatoes'] as String?,
    metascore: json['metascore'] as String?,
    awards: json['awards'] as String?,
    boxOffice: json['boxOffice'] as String?,
  );
}

class NextEpisodeSchedule {
  const NextEpisodeSchedule({
    required this.name,
    required this.airdate,
    this.airtime,
    required this.season,
    required this.number,
  });

  final String name;
  final String airdate;
  final String? airtime;
  final int season;
  final int number;

  factory NextEpisodeSchedule.fromJson(Map<String, dynamic> json) =>
      NextEpisodeSchedule(
        name: json['name'] as String? ?? 'TBA',
        airdate: json['airdate'] as String? ?? '',
        airtime: json['airtime'] as String?,
        season: (json['season'] as num?)?.toInt() ?? 1,
        number: (json['number'] as num?)?.toInt() ?? 1,
      );
}

class TVSchedule {
  const TVSchedule({
    this.network,
    this.days = const <String>[],
    this.time,
    this.nextEpisode,
  });

  final String? network;
  final List<String> days;
  final String? time;
  final NextEpisodeSchedule? nextEpisode;

  bool get hasSchedule =>
      (network != null && network!.isNotEmpty) || nextEpisode != null;

  factory TVSchedule.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final daysList = rawDays is List
        ? rawDays.whereType<String>().toList(growable: false)
        : const <String>[];

    final nextEpObj = json['nextEpisode'];
    final nextEp = nextEpObj is Map
        ? NextEpisodeSchedule.fromJson(nextEpObj.cast<String, dynamic>())
        : null;

    return TVSchedule(
      network: json['network'] as String?,
      days: daysList,
      time: json['time'] as String?,
      nextEpisode: nextEp,
    );
  }
}

