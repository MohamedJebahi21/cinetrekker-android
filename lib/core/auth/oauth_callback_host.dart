import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/app_router.dart';
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
      _subscription = _appLinks.uriLinkStream.listen(_handleUri);
    } catch (_) {
      // Deep-link support is optional on devices without an initial URI.
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
        } catch (_) {
          // AuthController exposes the error state; do not surface raw provider data.
        }
      }
      return;
    }

    final targetPath = '/${uri.host}${uri.path}'.replaceAll('//', '/');
    try {
      ref.read(appRouterProvider).go(targetPath);
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
