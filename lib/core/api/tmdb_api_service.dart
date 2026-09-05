import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/environment.dart';
import '../models/media_models.dart';
import '../storage/local_cache_manager.dart';
import 'api_client.dart';

class TmdbApiService {
  TmdbApiService(this._dio);

  final Dio _dio;
  final Map<String, Future<Map<String, dynamic>>> _inFlightRequests =
      <String, Future<Map<String, dynamic>>>{};

  Future<Map<String, dynamic>> _fetchJson(
    String endpoint, {
    String language = 'en',
    Map<String, String> extraParams = const <String, String>{},
    bool includeAdult = false,
  }) async {
    final sortedParams = extraParams.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final paramsString = sortedParams
        .map((e) => '${e.key}_${e.value}')
        .join('_');
    final cacheKey =
        'tmdb_${endpoint.replaceAll('/', '_')}_${language}_${includeAdult}_$paramsString';

    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey]!;
    }

    final future = _executeFetch(
      endpoint: endpoint,
      language: language,
      extraParams: extraParams,
      includeAdult: includeAdult,
      cacheKey: cacheKey,
    );

    _inFlightRequests[cacheKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<Map<String, dynamic>> _executeFetch({
    required String endpoint,
    required String language,
    required Map<String, String> extraParams,
    required bool includeAdult,
    required String cacheKey,
  }) async {
    try {
      if (Environment.apiBaseUrl.isEmpty) {
        throw StateError('CINETREKKER_API_BASE_URL is not configured.');
      }

      if (kDebugMode) {
        debugPrint('[TMDB] Fetching $endpoint from ${Environment.apiBaseUrl}');
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/tmdb-proxy',
        queryParameters: <String, dynamic>{
          'endpoint': endpoint,
          'language': language,
          'include_adult': includeAdult ? 'true' : 'false',
          ...extraParams,
        },
      );

      final data = response.data;
      if (data == null) {
        throw StateError('Empty TMDB proxy response.');
      }

      if (kDebugMode) {
        debugPrint('[TMDB] OK $endpoint — ${data.keys.take(5)}');
      }

      // Save to cache asynchronously with 24 hour TTL
      LocalCacheManager.instance.write(
        cacheKey,
        data,
        ttl: const Duration(hours: 24),
      );

      return data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TMDB] CATCH $endpoint — $e');
      }
      // Attempt cache recovery on failure
      final cachedData = await LocalCacheManager.instance.read(cacheKey);
      if (cachedData != null) {
        if (kDebugMode) {
          debugPrint('[TMDB] CACHE HIT for $endpoint');
        }
        return cachedData;
      }
      rethrow;
    }
  }

  Future<TmdbPagedResponse<TmdbMedia>> trending({
    String mediaType = 'all',
    String timeWindow = 'day',
    String language = 'en',
    int page = 1,
    bool includeAdult = false,
  }) async {
    final json = await _fetchJson(
      '/trending/$mediaType/$timeWindow',
      language: language,
      includeAdult: includeAdult,
      extraParams: <String, String>{'page': page.toString()},
    );
    return TmdbPagedResponse.fromJson(json, TmdbMedia.fromJson);
  }

  Future<TmdbPagedResponse<TmdbMedia>> nowPlayingMovies({
    String language = 'en',
    int page = 1,
    bool includeAdult = false,
  }) async {
    final json = await _fetchJson(
      '/movie/now_playing',
      language: language,
      includeAdult: includeAdult,
      extraParams: <String, String>{'page': page.toString()},
    );
    return TmdbPagedResponse.fromJson(json, TmdbMedia.fromJson);
  }

  Future<TmdbPagedResponse<TmdbMedia>> search({
    required String query,
    required String type,
    String language = 'en',
    int page = 1,
    bool includeAdult = false,
  }) async {
    final endpoint = switch (type) {
      'movie' => '/search/movie',
      'tv' => '/search/tv',
      'person' => '/search/person',
      _ => '/search/multi',
    };

    final json = await _fetchJson(
      endpoint,
      language: language,
      includeAdult: includeAdult,
      extraParams: <String, String>{'query': query, 'page': page.toString()},
    );
    return TmdbPagedResponse.fromJson(json, TmdbMedia.fromJson);
  }

  Future<TmdbMediaDetails> details({
    required String mediaType,
    required int mediaId,
    String language = 'en',
  }) async {
    final endpoint = '/$mediaType/$mediaId';
    final append = mediaType == 'movie'
        ? 'credits,similar,recommendations,release_dates,videos,keywords,external_ids,images,watch/providers'
        : 'credits,similar,recommendations,content_ratings,videos,keywords,external_ids,images,watch/providers';

    final json = await _fetchJson(
      endpoint,
      language: language,
      extraParams: <String, String>{'append_to_response': append},
    );
    return TmdbMediaDetails.fromJson(json);
  }

  Future<TmdbSeasonDetails> seasonDetails({
    required int tvId,
    required int seasonNumber,
    String language = 'en',
  }) async {
    final json = await _fetchJson(
      '/tv/$tvId/season/$seasonNumber',
      language: language,
    );
    return TmdbSeasonDetails.fromJson(json);
  }

  Future<TmdbPersonDetails> personDetails({
    required int personId,
    String language = 'en',
  }) async {
    final json = await _fetchJson(
      '/person/$personId',
      language: language,
      extraParams: <String, String>{
        'append_to_response': 'combined_credits,external_ids,images',
      },
    );
    return TmdbPersonDetails.fromJson(json);
  }

  Future<TmdbPagedResponse<TmdbMedia>> similar({
    required String mediaType,
    required int mediaId,
    String language = 'en',
  }) async {
    final json = await _fetchJson(
      '/$mediaType/$mediaId/similar',
      language: language,
    );
    return TmdbPagedResponse.fromJson(json, TmdbMedia.fromJson);
  }

  Future<TmdbPagedResponse<TmdbMedia>> recommendations({
    required String mediaType,
    required int mediaId,
    String language = 'en',
  }) async {
    final json = await _fetchJson(
      '/$mediaType/$mediaId/recommendations',
      language: language,
    );
    return TmdbPagedResponse.fromJson(json, TmdbMedia.fromJson);
  }

  Future<TmdbPagedResponse<TmdbMedia>> discover({
    required String mediaType,
    String language = 'en',
    int page = 1,
    Map<String, String> params = const <String, String>{},
  }) async {
    final endpoint = mediaType == 'tv' ? '/discover/tv' : '/discover/movie';
    final json = await _fetchJson(
      endpoint,
      language: language,
      extraParams: <String, String>{'page': page.toString(), ...params},
    );
    return TmdbPagedResponse.fromJson(json, TmdbMedia.fromJson);
  }
}

final tmdbApiServiceProvider = Provider<TmdbApiService>((ref) {
  return TmdbApiService(ref.read(apiClientProvider));
});
