import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/environment.dart';

/// Provides a stream that emits [true] when the device is online, [false] when offline.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  // Emit initial state
  yield await _checkConnectivity();

  // Poll every 5 seconds while the provider is alive
  await for (final _ in Stream<void>.periodic(const Duration(seconds: 5))) {
    yield await _checkConnectivity();
  }
});

Future<bool> _checkConnectivity() async {
  final apiUri = Uri.tryParse(Environment.apiBaseUrl);
  final host = apiUri?.host;
  if (host == null || host.isEmpty) {
    return true;
  }

  try {
    // Check the service CineTrekker actually uses. Public DNS for an unrelated
    // domain can be blocked on a working mobile network, producing a false
    // offline banner while the app itself is loading content successfully.
    final result = await InternetAddress.lookup(host);
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } catch (_) {
    return false;
  }
}

/// A banner that slides down from the top of the screen when offline,
/// and slides away again when connectivity is restored.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);

    final isOffline = connectivityState.when(
      data: (online) => !online,
      loading: () => false, // Don't flash the banner on first load
      error: (_, __) => false,
    );

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: isOffline ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isOffline ? 1 : 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'No internet connection',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
