import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/accessibility/reduced_motion_controller.dart';
import 'core/accessibility/text_scale_controller.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/offline_banner.dart';
import 'router/app_router.dart';
import 'shared/widgets/startup_config_gate.dart';

class CineTrekkerApp extends ConsumerWidget {
  const CineTrekkerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeStyle = ref.watch(themeControllerProvider);
    final textScaleStyle = ref.watch(textScaleControllerProvider);
    final reducedMotionStyle = ref.watch(reducedMotionControllerProvider);
    final localeStyle = ref.watch(localeControllerProvider);
    final locale = switch (localeStyle) {
      CineTrekkerLocaleStyle.system => null,
      CineTrekkerLocaleStyle.en => const Locale('en'),
      CineTrekkerLocaleStyle.ar => const Locale('ar'),
      CineTrekkerLocaleStyle.fr => const Locale('fr'),
      CineTrekkerLocaleStyle.es => const Locale('es'),
      CineTrekkerLocaleStyle.de => const Locale('de'),
      CineTrekkerLocaleStyle.tr => const Locale('tr'),
    };
    final router = ref.watch(appRouterProvider);
    final themeMode = switch (themeStyle) {
      CineTrekkerThemeStyle.system => ThemeMode.system,
      CineTrekkerThemeStyle.light => ThemeMode.light,
      CineTrekkerThemeStyle.dark => ThemeMode.dark,
      CineTrekkerThemeStyle.oled => ThemeMode.dark,
    };

    return StartupConfigGate(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'CineTrekker',
        themeMode: themeMode,
        locale: locale,
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
          Locale('es'),
          Locale('de'),
          Locale('tr'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        darkTheme: themeStyle == CineTrekkerThemeStyle.oled
            ? AppTheme.oled()
            : AppTheme.dark(),
        routerConfig: router,
        builder: (context, child) {
          Widget base = child ?? const SizedBox.shrink();
          final textScaleFactor = switch (textScaleStyle) {
            CineTrekkerTextScaleStyle.system => null,
            CineTrekkerTextScaleStyle.large => 1.15,
            CineTrekkerTextScaleStyle.xLarge => 1.3,
          };

          if (textScaleFactor != null) {
            final mediaQuery = MediaQuery.of(context);
            base = MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(textScaleFactor),
              ),
              child: base,
            );
          }

          final mediaQuery = MediaQuery.of(context);
          base = MediaQuery(
            data: mediaQuery.copyWith(
              disableAnimations:
                  reducedMotionStyle == CineTrekkerMotionStyle.reduced,
            ),
            child: base,
          );

          final colorScheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: colorScheme.surface,
              systemNavigationBarColor: colorScheme.surface,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemStatusBarContrastEnforced: false,
              systemNavigationBarContrastEnforced: false,
            ),
            child: Stack(
              children: [
                base,
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(bottom: false, child: OfflineBanner()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
