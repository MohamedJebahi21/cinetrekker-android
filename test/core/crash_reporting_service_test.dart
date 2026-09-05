import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrekker_android/core/utils/crash_reporting_service.dart';

void main() {
  group('CrashReportingService', () {
    test('instance returns singleton', () {
      final a = CrashReportingService.instance;
      final b = CrashReportingService.instance;
      expect(identical(a, b), isTrue);
    });

    test('recordError with all fields does not throw', () {
      expect(
        () => CrashReportingService.instance.recordError(
          Exception('test error'),
          StackTrace.current,
          reason: 'Test reason',
        ),
        returnsNormally,
      );
    });

    test('recordError with null stack does not throw', () {
      expect(
        () => CrashReportingService.instance.recordError(
          'a plain string error',
          null,
        ),
        returnsNormally,
      );
    });

    test('recordFlutterError does not throw', () {
      final details = FlutterErrorDetails(
        exception: Exception('widget error'),
        stack: StackTrace.current,
      );
      expect(
        () => CrashReportingService.instance.recordFlutterError(details),
        returnsNormally,
      );
    });
  });
}
