import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get supabaseUrl =>
      _envValue('CINETREKKER_SUPABASE_URL') ??
      const String.fromEnvironment(
        'CINETREKKER_SUPABASE_URL',
        defaultValue: '',
      );

  static String get supabaseAnonKey =>
      _envValue('CINETREKKER_SUPABASE_ANON_KEY') ??
      const String.fromEnvironment(
        'CINETREKKER_SUPABASE_ANON_KEY',
        defaultValue: '',
      );

  static String get apiBaseUrl =>
      _envValue('CINETREKKER_API_BASE_URL') ??
      const String.fromEnvironment(
        'CINETREKKER_API_BASE_URL',
        defaultValue: '',
      );

  static bool get hasSupabaseConfig =>
      _isConfiguredUrl(supabaseUrl) && supabaseAnonKey.isNotEmpty;

  static bool get hasApiConfig => _isConfiguredUrl(apiBaseUrl);

  static bool get hasRequiredRuntimeConfig => hasSupabaseConfig && hasApiConfig;

  static List<String> get missingRuntimeConfigKeys {
    final keys = <String>[];
    if (!_isConfiguredUrl(supabaseUrl)) {
      keys.add('CINETREKKER_SUPABASE_URL');
    }
    if (supabaseAnonKey.isEmpty) {
      keys.add('CINETREKKER_SUPABASE_ANON_KEY');
    }
    if (!_isConfiguredUrl(apiBaseUrl)) {
      keys.add('CINETREKKER_API_BASE_URL');
    }
    return keys;
  }

  static bool _isConfiguredUrl(String value) {
    if (value.trim().isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }

    return uri.host.toLowerCase() != 'example.com';
  }

  static String? _envValue(String key) {
    final value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}
