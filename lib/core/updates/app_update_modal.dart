import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import '../motion/haptic_service.dart';
import 'app_update_controller.dart';

Future<void> showAppUpdateModal(BuildContext context, WidgetRef ref) async {
  Haptics.light();

  // If idle or error, kick off a fresh check
  final currentState = ref.read(appUpdateControllerProvider);
  if (currentState.status == AppUpdateStatus.idle ||
      currentState.status == AppUpdateStatus.error) {
    unawaited(ref.read(appUpdateControllerProvider.notifier).checkForUpdates(isManual: true));
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalContext) => const _AppUpdateSheetContent(),
  );
}

class _AppUpdateSheetContent extends ConsumerWidget {
  const _AppUpdateSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final updateState = ref.watch(appUpdateControllerProvider);
    final updateNotifier = ref.read(appUpdateControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (updateState.status) {
            AppUpdateStatus.checking => _buildCheckingView(theme),
            AppUpdateStatus.updateAvailable => _buildUpdateAvailableView(
                context,
                theme,
                isDark,
                updateState,
                updateNotifier,
              ),
            AppUpdateStatus.upToDate => _buildUpToDateView(
                context,
                theme,
                isDark,
                updateState,
                updateNotifier,
              ),
            AppUpdateStatus.error => _buildErrorView(
                context,
                theme,
                updateState,
                updateNotifier,
              ),
            AppUpdateStatus.idle => _buildIdleView(
                context,
                theme,
                updateNotifier,
              ),
          },
        ),
      ),
    );
  }

  Widget _buildCheckingView(ThemeData theme) {
    return Column(
      key: const ValueKey('checking-view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator.adaptive(strokeWidth: 3),
        ),
        const SizedBox(height: 16),
        Text(
          'Checking for updates...',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Comparing with latest GitHub release for CineTrekker.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUpdateAvailableView(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppUpdateState state,
    AppUpdateController notifier,
  ) {
    final info = state.updateInfo;
    final latestVersion = info?.latestVersion ?? 'New Version';
    final hasApk = info?.apkDownloadUrl != null;

    return Column(
      key: const ValueKey('update-available-view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'UPDATE AVAILABLE',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          info?.releaseTitle ?? 'CineTrekker v$latestVersion',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Current installed: ${AppConstants.versionDisplay}  →  New release: v$latestVersion',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 14),
        if (info?.releaseNotes != null && info!.releaseNotes!.trim().isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : theme.colorScheme.secondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                info.releaseNotes!.trim(),
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              Haptics.medium();
              if (hasApk) {
                await notifier.openDirectDownload();
              } else {
                await notifier.openUpdatePage();
              }
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(
              hasApk ? 'Download APK Update' : 'Go to Update Page',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              Haptics.selection();
              await notifier.openUpdatePage();
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(
              'View Release on GitHub',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpToDateView(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppUpdateState state,
    AppUpdateController notifier,
  ) {
    return Column(
      key: const ValueKey('up-to-date-view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.green,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "You're up to date!",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'CineTrekker ${AppConstants.fullVersion} is currently the latest version available.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.checkForUpdates(isManual: true),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Check Again',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    ThemeData theme,
    AppUpdateState state,
    AppUpdateController notifier,
  ) {
    return Column(
      key: const ValueKey('error-view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        Icon(
          Icons.cloud_off_rounded,
          color: theme.colorScheme.error,
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          'Could not check for updates',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please verify your connection or visit the GitHub releases page directly.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.checkForUpdates(isManual: true),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  await notifier.openUpdatePage();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Open GitHub',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdleView(
    BuildContext context,
    ThemeData theme,
    AppUpdateController notifier,
  ) {
    return Column(
      key: const ValueKey('idle-view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'App Updates',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check GitHub releases for the latest version of CineTrekker.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => notifier.checkForUpdates(isManual: true),
          child: const Text('Check Now'),
        ),
      ],
    );
  }
}
