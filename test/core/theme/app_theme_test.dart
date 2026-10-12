import 'package:cinetrekker_android/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme', () {
    test('light theme has correct brightness and Material 3 enabled', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark theme has correct brightness and Material 3 enabled', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('oled theme has pure black background and Material 3 enabled', () {
      final theme = AppTheme.oled();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, Colors.black);
    });

    test('uses ZoomPageTransitionsBuilder for native Android feel', () {
      final theme = AppTheme.dark();
      final androidBuilder =
          theme.pageTransitionsTheme.builders[TargetPlatform.android];
      expect(androidBuilder, isA<ZoomPageTransitionsBuilder>());
    });
  });
}
