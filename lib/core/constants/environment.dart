class Environment {
  static String get supabaseUrl => const String.fromEnvironment(
    'CINETREKKER_SUPABASE_URL',
    defaultValue: '',
  );

  static String get supabaseAnonKey => const String.fromEnvironment(
    'CINETREKKER_SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get apiBaseUrl => const String.fromEnvironment(
    'CINETREKKER_API_BASE_URL',
    defaultValue: '',
  );

  /// Optional Sentry DSN. When empty, crashes are only logged locally.
  static String get sentryDsn => const String.fromEnvironment(
    'CINETREKKER_SENTRY_DSN',
    defaultValue: '',
  );

  static bool get hasSentryConfig => sentryDsn.trim().isNotEmpty;

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
}
