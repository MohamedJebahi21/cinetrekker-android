import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/auth/oauth_callback_host.dart';
import 'core/errors/app_crash_fallback.dart';
import 'core/utils/crash_reporting_service.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize the crash reporting service
      CrashReportingService.instance.initialize();

      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {
        // The app can still run with dart-defines for development and CI.
      }

      ErrorWidget.builder = (details) {
        return const AppCrashFallback();
      };

      runApp(
        const ProviderScope(child: OAuthCallbackHost(child: CineTrekkerApp())),
      );
    },
    (error, stack) {
      CrashReportingService.instance.recordError(
        error,
        stack,
        reason: 'Uncaught zone error',
      );
    },
  );
}
