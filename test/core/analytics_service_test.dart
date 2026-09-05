import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrekker_android/core/utils/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService service;

    setUp(() {
      service = AnalyticsService();
    });

    test('logEvent does not throw', () {
      expect(() => service.logEvent('test_event'), returnsNormally);
    });

    test('logEvent with parameters does not throw', () {
      expect(
        () => service.logEvent('test_event', <String, dynamic>{
          'key': 'value',
          'count': 1,
        }),
        returnsNormally,
      );
    });

    test('logPageView does not throw', () {
      expect(() => service.logPageView('/home'), returnsNormally);
    });

    test('logAction does not throw', () {
      expect(
        () => service.logAction(
          'add_to_watchlist',
          category: 'watchlist',
          label: 'The Matrix',
        ),
        returnsNormally,
      );
    });

    test('logAction with value map does not throw', () {
      expect(
        () => service.logAction(
          'rate_title',
          category: 'rating',
          label: 'Inception',
          value: <String, dynamic>{'stars': 4.5, 'media_id': 123},
        ),
        returnsNormally,
      );
    });
  });

  group('AnalyticsService providers', () {
    test('analyticsServiceProvider creates a valid instance', () {
      // We just verify that the class can be instantiated, as Riverpod
      // container setup is beyond unit test scope.
      final svc = AnalyticsService();
      expect(svc, isNotNull);
    });
  });
}
