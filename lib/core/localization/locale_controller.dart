import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

enum CineTrekkerLocaleStyle { system, en, ar, fr, de, es, tr }

final localeControllerProvider =
    NotifierProvider<LocaleController, CineTrekkerLocaleStyle>(
      LocaleController.new,
    );

class LocaleController extends Notifier<CineTrekkerLocaleStyle> {
  static const _storage = FlutterSecureStorage();

  @override
  CineTrekkerLocaleStyle build() {
    _load();
    return CineTrekkerLocaleStyle.system;
  }

  Future<void> _load() async {
    final value = await _storage.read(key: AppConstants.localeStorageKey);
    state = switch (value) {
      'en' => CineTrekkerLocaleStyle.en,
      'ar' => CineTrekkerLocaleStyle.ar,
      'fr' => CineTrekkerLocaleStyle.fr,
      'de' => CineTrekkerLocaleStyle.de,
      'es' => CineTrekkerLocaleStyle.es,
      'tr' => CineTrekkerLocaleStyle.tr,
      _ => CineTrekkerLocaleStyle.system,
    };
  }

  Future<void> setLocale(CineTrekkerLocaleStyle style) async {
    state = style;
    await _storage.write(
      key: AppConstants.localeStorageKey,
      value: switch (style) {
        CineTrekkerLocaleStyle.system => 'system',
        CineTrekkerLocaleStyle.en => 'en',
        CineTrekkerLocaleStyle.ar => 'ar',
        CineTrekkerLocaleStyle.fr => 'fr',
        CineTrekkerLocaleStyle.de => 'de',
        CineTrekkerLocaleStyle.es => 'es',
        CineTrekkerLocaleStyle.tr => 'tr',
      },
    );
  }
}

String tmdbLanguageCodeForLocaleStyle(
  CineTrekkerLocaleStyle style, {
  Locale? systemLocale,
}) {
  if (style == CineTrekkerLocaleStyle.system) {
    final language = systemLocale?.languageCode.toLowerCase();
    return const <String>{'en', 'ar', 'fr', 'de', 'es', 'tr'}.contains(language)
        ? language!
        : 'en';
  }
  return switch (style) {
    CineTrekkerLocaleStyle.en => 'en',
    CineTrekkerLocaleStyle.ar => 'ar',
    CineTrekkerLocaleStyle.fr => 'fr',
    CineTrekkerLocaleStyle.de => 'de',
    CineTrekkerLocaleStyle.es => 'es',
    CineTrekkerLocaleStyle.tr => 'tr',
    CineTrekkerLocaleStyle.system => 'en',
  };
}

final tmdbLanguageProvider = Provider<String>((ref) {
  final style = ref.watch(localeControllerProvider);
  final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
  return tmdbLanguageCodeForLocaleStyle(style, systemLocale: systemLocale);
});
