class AppConstants {
  AppConstants._();

  static const String appVersion = '1.1.3';
  static const int buildNumber = 6;
  static const String fullVersion = 'Version $appVersion (build $buildNumber)';
  static const String versionDisplay = 'v$appVersion';

  static const String githubRepo = 'MohamedJebahi21/cinetrekker-android';
  static const String githubReleasesLatestApiUrl =
      'https://api.github.com/repos/MohamedJebahi21/cinetrekker-android/releases/latest';
  static const String githubReleasesPageUrl =
      'https://github.com/MohamedJebahi21/cinetrekker-android/releases';

  static const String themeStorageKey = 'cinetrekker_theme_style';
  static const String textScaleStorageKey = 'cinetrekker_text_scale';
  static const String fontSizeScaleStorageKey = 'cinetrekker_font_size_scale';
  static const String localeStorageKey = 'cinetrekker_locale_style';
  static const String authSessionStorageKey = 'cinetrekker_auth_session';
  static const String contentSafetyStorageKey = 'cinetrekker_content_safety';
  static const String reducedMotionStorageKey = 'cinetrekker_reduced_motion';
  static const String episodeRemindersStorageKey =
      'cinetrekker_episode_reminders_pref';
}
