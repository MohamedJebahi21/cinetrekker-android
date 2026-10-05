class Environment {
  static const String defaultSupabaseUrl =
      'https://nvssyuxghwlubxklvgrn.supabase.co';
  static const String defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52c3N5dXhnaHdsdWJ4a2x2Z3JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1NjI1NDgsImV4cCI6MjA4NjEzODU0OH0.O2kkd5tu-u-pKq9vVkTT7-4SnZ-kA1YBagdski-U8nQ';
  static const String defaultApiBaseUrl = 'https://cinetrekker.vercel.app';

  static String get supabaseUrl => const String.fromEnvironment(
    'CINETREKKER_SUPABASE_URL',
    defaultValue: defaultSupabaseUrl,
  );

  static String get supabaseAnonKey => const String.fromEnvironment(
    'CINETREKKER_SUPABASE_ANON_KEY',
    defaultValue: defaultSupabaseAnonKey,
  );

  static String get apiBaseUrl => const String.fromEnvironment(
    'CINETREKKER_API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  /// Optional Sentry DSN. When empty, crashes are only logged locally.
  static String get sentryDsn => const String.fromEnvironment(
    'CINETREKKER_SENTRY_DSN',
    defaultValue: '',
  );

  static bool get hasSentryConfig => sentryDsn.trim().isNotEmpty;

  static bool get hasSupabaseConfig =>
      _isConfiguredUrl(supabaseUrl) && supabaseAnonKey.trim().isNotEmpty;

  static bool get hasApiConfig => _isConfiguredUrl(apiBaseUrl);

  static bool get hasRequiredRuntimeConfig => hasSupabaseConfig && hasApiConfig;

  static List<String> get missingRuntimeConfigKeys {
    final keys = <String>[];
    if (!_isConfiguredUrl(supabaseUrl)) {
      keys.add('CINETREKKER_SUPABASE_URL');
    }
    if (supabaseAnonKey.trim().isEmpty) {
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
}
