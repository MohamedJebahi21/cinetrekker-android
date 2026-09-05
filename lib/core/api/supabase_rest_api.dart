import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../constants/environment.dart';

class SupabaseRestApi {
  SupabaseRestApi({required this.accessToken});

  final String? accessToken;

  Dio get _dio => Dio(
    BaseOptions(
      baseUrl: '${Environment.supabaseUrl}/rest/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: _headers,
    ),
  );

  Map<String, String> get _headers => <String, String>{
    'apikey': Environment.supabaseAnonKey,
    'Authorization': 'Bearer ${accessToken ?? Environment.supabaseAnonKey}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<Map<String, dynamic>>> selectRows(
    String table, {
    Map<String, dynamic> equals = const <String, dynamic>{},
    String? orderBy,
    bool descending = false,
  }) async {
    final query = <String, dynamic>{};
    for (final entry in equals.entries) {
      query[entry.key] = 'eq.${entry.value}';
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
      query[entry.key] = 'eq.${entry.value}';
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
  return SupabaseRestApi(accessToken: authState.valueOrNull?.accessToken);
});
