import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_models.dart';
import '../storage/local_cache_manager.dart';
import 'api_client.dart';

class EnrichmentApiService {
  EnrichmentApiService(this._dio);

  final Dio _dio;

  Future<EnrichedRatings?> getRatings(String imdbId) async {
    if (imdbId.isEmpty) return null;

    final cacheKey = 'enrichment_ratings_$imdbId';
    final cached = await LocalCacheManager.instance.read(cacheKey);
    if (cached is Map<String, dynamic>) {
      return EnrichedRatings.fromJson(cached);
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/enrichment/ratings',
        queryParameters: <String, dynamic>{'imdb_id': imdbId},
      );

      final data = response.data;
      if (data == null) return null;

      // Cache for 7 days
      LocalCacheManager.instance.write(
        cacheKey,
        data,
        ttl: const Duration(days: 7),
      );

      return EnrichedRatings.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Enrichment] Ratings fetch error: $e');
      }
      return null;
    }
  }

  Future<TVSchedule?> getTVSchedule(String imdbId) async {
    if (imdbId.isEmpty) return null;

    final cacheKey = 'enrichment_tv_schedule_$imdbId';
    final cached = await LocalCacheManager.instance.read(cacheKey);
    if (cached is Map<String, dynamic>) {
      return TVSchedule.fromJson(cached);
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/enrichment/tv-schedule',
        queryParameters: <String, dynamic>{'imdb_id': imdbId},
      );

      final data = response.data;
      if (data == null) return null;

      // Cache for 6 hours
      LocalCacheManager.instance.write(
        cacheKey,
        data,
        ttl: const Duration(hours: 6),
      );

      return TVSchedule.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Enrichment] TV Schedule fetch error: $e');
      }
      return null;
    }
  }
}

final enrichmentApiServiceProvider = Provider<EnrichmentApiService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return EnrichmentApiService(dio);
});

final enrichedRatingsProvider =
    FutureProvider.family<EnrichedRatings?, String>((ref, imdbId) async {
      if (imdbId.isEmpty) return null;
      final service = ref.watch(enrichmentApiServiceProvider);
      return service.getRatings(imdbId);
    });

final tvScheduleProvider =
    FutureProvider.family<TVSchedule?, String>((ref, imdbId) async {
      if (imdbId.isEmpty) return null;
      final service = ref.watch(enrichmentApiServiceProvider);
      return service.getTVSchedule(imdbId);
    });
