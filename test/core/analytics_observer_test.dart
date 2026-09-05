import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrekker_android/core/utils/analytics_service.dart';

// AnalyticsObserver requires a live NavigatorObserver + Route interaction,
// so we do lightweight structural smoke tests here.
void main() {
  group('AnalyticsObserver', () {
    test('can be instantiated with a valid AnalyticsService', () {
      final analytics = AnalyticsService();
      final observer = AnalyticsObserver(analytics);
      expect(observer, isNotNull);
    });
  });
}
