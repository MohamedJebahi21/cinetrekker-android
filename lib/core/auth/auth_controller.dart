import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../constants/environment.dart';
import 'auth_session.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, CineTrekkerAuthSession?>(
      AuthController.new,
    );

class AuthController extends AsyncNotifier<CineTrekkerAuthSession?> {
  static const _storage = FlutterSecureStorage();

  Dio get _dio => Dio(
    BaseOptions(
      baseUrl: '${Environment.supabaseUrl}/auth/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: <String, String>{
        'apikey': Environment.supabaseAnonKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  @override
  Future<CineTrekkerAuthSession?> build() async {
    if (!Environment.hasSupabaseConfig) return null;
    final stored = await _storage.read(key: AppConstants.authSessionStorageKey);
    if (stored == null || stored.isEmpty) return null;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) return null;
      final session = CineTrekkerAuthSession.fromJson(
        decoded.cast<String, dynamic>(),
      );
      if (!session.isExpired) return session;
      if (session.refreshToken.isEmpty) return null;
      return await _refresh(session.refreshToken);
    } catch (_) {
      await _storage.delete(key: AppConstants.authSessionStorageKey);
      return null;
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _run(() async {
      final payload = await _post(
        '/token?grant_type=password',
        <String, dynamic>{'email': email.trim(), 'password': password},
      );
      final session = CineTrekkerAuthSession.fromApiJson(payload);
      await _persist(session);
      return session;
    });
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await _run(() async {
      final payload = await _post('/signup', <String, dynamic>{
        'email': email.trim(),
        'password': password,
        if (metadata.isNotEmpty) 'data': metadata,
      });
      final accessToken = payload['access_token'];
      final user = payload['user'];
      if (accessToken is String && accessToken.isNotEmpty && user is Map) {
        final session = CineTrekkerAuthSession.fromApiJson(payload);
        await _persist(session);
        return session;
      }
      return null;
    });
  }

  Future<void> sendPasswordReset({
    required String email,
    String? redirectTo,
  }) async {
    await _run(() async {
      await _post('/recover', <String, dynamic>{
        'email': email.trim(),
        if (redirectTo != null && redirectTo.isNotEmpty)
          'redirect_to': redirectTo,
      });
      return state.valueOrNull;
    }, preserveSession: true);
  }

  Future<void> signInWithGoogle() async {
    final uri = Uri.parse('${Environment.supabaseUrl}/auth/v1/authorize')
        .replace(
          queryParameters: <String, String>{
            'provider': 'google',
            'redirect_to': 'cinetrekker://auth/callback',
          },
        );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw StateError('Could not open the Google sign-in page.');
    }
  }

  Future<void> completeOAuthCallback(Uri uri) async {
    await _run(() async {
      final values = <String, String>{
        if (uri.fragment.isNotEmpty) ...Uri.splitQueryString(uri.fragment),
        ...uri.queryParameters,
      };
      final accessToken = values['access_token'];
      final refreshToken = values['refresh_token'];
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        throw StateError('Google sign-in did not return a complete session.');
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/user',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );
      final user = response.data;
      if (user == null) {
        throw const FormatException('Google sign-in returned no user.');
      }
      final expiresIn = int.tryParse(values['expires_in'] ?? '') ?? 3600;
      final session = CineTrekkerAuthSession.fromApiJson(<String, dynamic>{
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': values['token_type'] ?? 'bearer',
        'expires_in': expiresIn,
        'expires_at': int.tryParse(values['expires_at'] ?? ''),
        'user': user,
      });
      await _persist(session);
      return session;
    });
  }

  Future<void> signOut() async {
    final current = state.valueOrNull;
    try {
      if (current != null && current.accessToken.isNotEmpty) {
        await _dio.post<void>(
          '/logout',
          options: Options(
            headers: <String, String>{
              'Authorization': 'Bearer ${current.accessToken}',
            },
          ),
        );
      }
    } finally {
      await _storage.delete(key: AppConstants.authSessionStorageKey);
      state = const AsyncData<CineTrekkerAuthSession?>(null);
    }
  }

  Future<CineTrekkerAuthSession?> _refresh(String refreshToken) async {
    final payload = await _post(
      '/token?grant_type=refresh_token',
      <String, dynamic>{'refresh_token': refreshToken},
    );
    final session = CineTrekkerAuthSession.fromApiJson(payload);
    await _persist(session);
    return session;
  }

  Future<void> _run(
    Future<CineTrekkerAuthSession?> Function() operation, {
    bool preserveSession = false,
  }) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading<CineTrekkerAuthSession?>();
    try {
      final result = await operation();
      state = AsyncData<CineTrekkerAuthSession?>(result);
    } catch (error, stackTrace) {
      state = AsyncError<CineTrekkerAuthSession?>(error, stackTrace);
      if (preserveSession && previous != null) {
        state = AsyncData<CineTrekkerAuthSession?>(previous);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null)
        throw const FormatException('Empty authentication response.');
      return data;
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map) {
        final message =
            data['msg'] ??
            data['message'] ??
            data['error_description'] ??
            data['error'];
        if (message != null) throw StateError(message.toString());
      }
      throw StateError(error.message ?? 'Authentication request failed.');
    }
  }

  Future<void> _persist(CineTrekkerAuthSession session) async {
    await _storage.write(
      key: AppConstants.authSessionStorageKey,
      value: jsonEncode(session.toStorageJson()),
    );
  }
}
