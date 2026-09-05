import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/auth/oauth_callback_host.dart';
import 'core/constants/environment.dart';
import 'core/errors/app_crash_fallback.dart';
import 'core/utils/crash_reporting_service.dart';

Future<void> main() async {
  final completer = Completer<void>();

  runZonedGuarded(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();

        CrashReportingService.instance.initialize(
          sentryEnabled: Environment.hasSentryConfig,
        );

        ErrorWidget.builder = (_) => const AppCrashFallback();

        const app = ProviderScope(
          child: OAuthCallbackHost(child: CineTrekkerApp()),
        );

        if (Environment.hasSentryConfig) {
          await SentryFlutter.init((options) {
            options.dsn = Environment.sentryDsn;
            options.environment = kReleaseMode ? 'production' : 'development';
            options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
            options.sendDefaultPii = false;
          }, appRunner: () => runApp(app));
        } else {
          runApp(app);
        }
        if (!completer.isCompleted) completer.complete();
      } catch (error, stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
        rethrow;
      }
    },
    (error, stack) {
      CrashReportingService.instance.recordError(
        error,
        stack,
        reason: 'Uncaught zone error',
      );
      if (!completer.isCompleted) completer.completeError(error, stack);
    },
  );

  await completer.future;
}
