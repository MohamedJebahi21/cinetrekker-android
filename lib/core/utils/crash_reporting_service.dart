import 'package:flutter/foundation.dart';

class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  void initialize() {
    // Intercept Flutter framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      recordFlutterError(details);
    };

    // Intercept asynchronous platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, reason: 'Uncaught platform error');
      return true;
    };
  }

  void recordError(dynamic error, StackTrace? stack, {String? reason}) {
    // In development/debug mode, print clean reports. In production, send to Sentry/Firebase Crashlytics.
    if (kDebugMode) {
      debugPrint('[CrashReporter] Uncaught Error: $error');
      if (reason != null) {
        debugPrint('[CrashReporter] Reason: $reason');
      }
      if (stack != null) {
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  void recordFlutterError(FlutterErrorDetails details) {
    recordError(
      details.exception,
      details.stack,
      reason:
          'Flutter framework error: ${details.context?.toString() ?? 'unknown context'}',
    );
  }
}
