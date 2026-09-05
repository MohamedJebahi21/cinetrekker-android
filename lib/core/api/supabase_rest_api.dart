import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../constants/environment.dart';

class SupabaseRestApi {
  SupabaseRestApi({
    required this.accessToken,
    Future<String?> Function()? refreshAccessToken,
  }) : _refreshAccessToken = refreshAccessToken;

  final String? accessToken;
  final Future<String?> Function()? _refreshAccessToken;
  Dio? _dioInstance;

  Dio get _dio {
    final existing = _dioInstance;
    if (existing != null) return existing;

    final dio = Dio(
      BaseOptions(
        baseUrl: '${Environment.supabaseUrl}/rest/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: _headersFor(accessToken),
      ),
    );

    final refresh = _refreshAccessToken;
    if (refresh != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) async {
            if (error.response?.statusCode != 401) {
              return handler.next(error);
            }

            try {
              final refreshed = await refresh();
              if (refreshed == null || refreshed.isEmpty) {
                return handler.next(error);
              }

              final request = error.requestOptions;
              request.headers['Authorization'] = 'Bearer $refreshed';
              final response = await dio.fetch<dynamic>(request);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(error);
            }
          },
        ),
      );
    }

    return _dioInstance = dio;
  }

  Map<String, String> _headersFor(String? token) => <String, String>{
    'apikey': Environment.supabaseAnonKey,
    'Authorization': 'Bearer ${token ?? Environment.supabaseAnonKey}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Builds a PostgREST `eq.` filter, quoting values that contain reserved chars.
  static String eqFilter(Object? value) {
    if (value is bool || value is num) {
      return 'eq.$value';
    }
    final raw = value?.toString() ?? '';
    if (RegExp(r'[\s,.()]').hasMatch(raw) || raw.contains('"')) {
      final escaped = raw.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      return 'eq."$escaped"';
    }
    return 'eq.$raw';
  }

  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, dynamic> equals = const <String, dynamic>{},
    String? orderBy,
    bool descending = false,
  }) async {
    final query = <String, dynamic>{};
    for (final entry in equals.entries) {
      query[entry.key] = eqFilter(entry.value);
    }
    if (orderBy != null && orderBy.isNotEmpty) {
      query['order'] = '$orderBy.${descending ? 'desc' : 'asc'}';
    }
    final response = await _dio.get<List<dynamic>>(
      '/$table',
      queryParameters: query,
    );
    final data = response.data;
    if (data == null) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<void> upsertRow(
    String table,
    Map<String, dynamic> row, {
    String? onConflict,
  }) async {
    final query = <String, dynamic>{};
    if (onConflict != null && onConflict.isNotEmpty) {
      query['on_conflict'] = onConflict;
    }
    await _dio.post<void>(
      '/$table',
      queryParameters: query,
      data: row,
      options: Options(
        headers: <String, String>{
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
      ),
    );
  }

  Future<void> deleteRows(
    String table, {
    Map<String, dynamic> equals = const <String, dynamic>{},
  }) async {
    final query = <String, dynamic>{};
    for (final entry in equals.entries) {
      query[entry.key] = eqFilter(entry.value);
    }
    await _dio.delete<void>(
      '/$table',
      queryParameters: query,
      options: Options(headers: <String, String>{'Prefer': 'return=minimal'}),
    );
  }
}

final supabaseRestApiProvider = Provider<SupabaseRestApi>((ref) {
  final authState = ref.watch(authControllerProvider);
  return SupabaseRestApi(
    accessToken: authState.valueOrNull?.accessToken,
    refreshAccessToken: () async {
      final session = await ref
          .read(authControllerProvider.notifier)
          .refreshSession();
      return session?.accessToken;
    },
  );
});
