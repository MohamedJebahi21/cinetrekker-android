import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  bool _sentryEnabled = false;

  void initialize({bool sentryEnabled = false}) {
    _sentryEnabled = sentryEnabled;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, reason: 'Uncaught platform error');
      return true;
    };
  }

  void recordError(dynamic error, StackTrace? stack, {String? reason}) {
    if (kDebugMode) {
      debugPrint('[CrashReporter] Uncaught Error: $error');
      if (reason != null) {
        debugPrint('[CrashReporter] Reason: $reason');
      }
      if (stack != null) {
        debugPrintStack(stackTrace: stack);
      }
    }

    if (_sentryEnabled) {
      Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) {
          if (reason != null && reason.isNotEmpty) {
            scope.setTag('reason', reason);
          }
        },
      );
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
