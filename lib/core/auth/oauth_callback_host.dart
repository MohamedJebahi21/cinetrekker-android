import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/app_router.dart';
import '../utils/crash_reporting_service.dart';
import 'auth_controller.dart';

class OAuthCallbackHost extends ConsumerStatefulWidget {
  const OAuthCallbackHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<OAuthCallbackHost> createState() => _OAuthCallbackHostState();
}

class _OAuthCallbackHostState extends ConsumerState<OAuthCallbackHost> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenForCallbacks();
  }

  Future<void> _listenForCallbacks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) await _handleUri(initialUri);
      _subscription = _appLinks.uriLinkStream.listen(
        _handleUri,
        onError: (Object error, StackTrace stackTrace) {
          CrashReportingService.instance.recordError(
            error,
            stackTrace,
            reason: 'Deep link stream error',
          );
        },
      );
    } catch (error, stackTrace) {
      // Deep-link support is optional on devices without an initial URI.
      if (kDebugMode) {
        debugPrint('[OAuthCallbackHost] Deep-link init failed: $error');
      }
      CrashReportingService.instance.recordError(
        error,
        stackTrace,
        reason: 'Deep link init failure',
      );
    }
  }

  Future<void> _handleUri(Uri uri) async {
    if (uri.scheme != 'cinetrekker') return;

    if (uri.host == 'auth') {
      if (uri.path == '/callback') {
        try {
          await ref
              .read(authControllerProvider.notifier)
              .completeOAuthCallback(uri);
        } catch (error, stackTrace) {
          // AuthController already exposes AsyncError; log for observability.
          if (kDebugMode) {
            debugPrint('[OAuthCallbackHost] OAuth callback failed: $error');
          }
          CrashReportingService.instance.recordError(
            error,
            stackTrace,
            reason: 'OAuth callback failure',
          );
        }
      }
      return;
    }

    final targetPath = '/${uri.host}${uri.path}'.replaceAll('//', '/');
    try {
      ref.read(appRouterProvider).go(targetPath);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[OAuthCallbackHost] Deep-link navigation failed: $error');
      }
      CrashReportingService.instance.recordError(
        error,
        stackTrace,
        reason: 'Deep link navigation failure',
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
