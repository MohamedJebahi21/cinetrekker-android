import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

enum CineTrekkerThemeStyle { system, light, dark, oled }

final _storage = FlutterSecureStorage();

final themeControllerProvider =
    NotifierProvider<ThemeController, CineTrekkerThemeStyle>(
      ThemeController.new,
    );

class ThemeController extends Notifier<CineTrekkerThemeStyle> {
  @override
  CineTrekkerThemeStyle build() {
    _load();
    return CineTrekkerThemeStyle.system;
  }

  Future<void> _load() async {
    final value = await _storage.read(key: AppConstants.themeStorageKey);
    state = switch (value) {
      'light' => CineTrekkerThemeStyle.light,
      'dark' => CineTrekkerThemeStyle.dark,
      'oled' => CineTrekkerThemeStyle.oled,
      _ => CineTrekkerThemeStyle.system,
    };
  }

  Future<void> setTheme(CineTrekkerThemeStyle style) async {
    state = style;
    await _storage.write(
      key: AppConstants.themeStorageKey,
      value: switch (style) {
        CineTrekkerThemeStyle.light => 'light',
        CineTrekkerThemeStyle.dark => 'dark',
        CineTrekkerThemeStyle.oled => 'oled',
        CineTrekkerThemeStyle.system => 'system',
      },
    );
  }
}
