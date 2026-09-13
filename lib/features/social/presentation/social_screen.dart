import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../shared/widgets/app_error_card.dart';
import 'notifications_controller.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).load();
    });
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }

  BoxDecoration _glassCard(ThemeData theme, bool isDark) {
    return BoxDecoration(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final notifier = ref.read(notificationsControllerProvider.notifier);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Social',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/people'),
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'People',
          ),
          if (session != null)
            TextButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      await notifier.markAllRead();
                    },
              child: Text(
                'Mark all read',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: notifier.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (state.isLoading)
              LinearProgressIndicator(
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
              ),
            if (state.error != null)
              AppErrorCard(
                message: state.error!,
                onRetry: () =>
                    ref.read(notificationsControllerProvider.notifier).load(),
              ),
            const SizedBox(height: 12),
            if (session == null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _glassCard(theme, isDark),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Join the CineTrekker Community',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to see activity from users you follow, get community notifications, and share reviews.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Sign in / Register'),
                    ),
                  ],
                ),
              )
            else if (state.notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.25,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Social activity and updates will appear here.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.50,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...state.notifications.map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      decoration: _glassCard(theme, isDark),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        onTap: () {
                          ref
                              .read(notificationsControllerProvider.notifier)
                              .markAsRead(notification.id);
                          if (notification.mediaId != null &&
                              notification.mediaType != null) {
                            context.push(
                              '/details/${notification.mediaType}/${notification.mediaId}',
                            );
                          } else if (notification.type == 'follower') {
                            context.push('/people');
                          }
                        },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: notification.isRead
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.06,
                                )
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                        ),
                        child: Icon(
                          notification.isRead
                              ? Icons.notifications_none_rounded
                              : Icons.notifications_active_rounded,
                          color: notification.isRead
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                )
                              : theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notification.message,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14.5,
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        notification.type.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      trailing: Text(
                        _timeAgo(notification.createdAt),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.40,
                          ),
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
