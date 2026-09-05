import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  AnalyticsService();

  void logEvent(String name, [Map<String, dynamic>? parameters]) {
    // In development, we log to stdout. In production, this can hook into Firebase, Mixpanel, or Supabase.
    if (kDebugMode) {
      debugPrint('[Analytics] Event: $name, Params: $parameters');
    }
  }

  void logPageView(String screenName) {
    logEvent('page_view', <String, dynamic>{'screen_name': screenName});
  }

  void logAction(
    String action, {
    required String category,
    String? label,
    Map<String, dynamic>? value,
  }) {
    logEvent('action', <String, dynamic>{
      'action': action,
      'category': category,
      if (label != null) 'label': label,
      if (value != null) ...value,
    });
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsObserver extends NavigatorObserver {
  AnalyticsObserver(this._analytics);
  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName =
        route.settings.name ?? route.settings.arguments?.toString();
    if (routeName != null) {
      _analytics.logPageView(routeName);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final routeName =
        newRoute?.settings.name ?? newRoute?.settings.arguments?.toString();
    if (routeName != null) {
      _analytics.logPageView(routeName);
    }
  }
}

final analyticsObserverProvider = Provider<AnalyticsObserver>((ref) {
  return AnalyticsObserver(ref.read(analyticsServiceProvider));
});
