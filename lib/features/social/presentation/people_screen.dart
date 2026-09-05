import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../shared/widgets/app_error_card.dart';
import 'people_controller.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(peopleControllerProvider.notifier).load();
    });
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
    final state = ref.watch(peopleControllerProvider);
    final controller = ref.read(peopleControllerProvider.notifier);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'People',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => ref.read(peopleControllerProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (session == null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: _glassCard(theme, isDark),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign in to follow people, see their updates, and share your watch history.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (session == null) const SizedBox(height: 12),
            if (state.error != null)
              AppErrorCard(
                message: state.error!,
                onRetry: () =>
                    ref.read(peopleControllerProvider.notifier).load(),
              ),
            if (state.isLoading)
              LinearProgressIndicator(
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
              ),
            const SizedBox(height: 16),
            if (state.people.isEmpty && state.error == null && !state.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    'No public profiles available.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...state.people.map((person) {
                final isFollowing = state.followingIds.contains(person.userId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: _glassCard(theme, isDark),
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          backgroundImage: person.avatarUrl == null
                              ? null
                              : CachedNetworkImageProvider(person.avatarUrl!),
                          child: person.avatarUrl == null
                              ? Icon(
                                  Icons.person_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                      title: Text(
                        person.displayName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        person.bio ?? 'No bio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.50,
                          ),
                        ),
                      ),
                      onTap: () => context.push('/user/${person.userId}'),
                      trailing: FilledButton(
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                if (session == null) {
                                  context.push('/auth');
                                  return;
                                }
                                if (isFollowing) {
                                  await controller.unfollowUser(person.userId);
                                } else {
                                  await controller.followUser(person.userId);
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: isFollowing
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                          foregroundColor: isFollowing
                              ? theme.colorScheme.onSurface
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: isFollowing
                                ? BorderSide(
                                    color: theme.colorScheme.outlineVariant,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          session == null
                              ? 'Sign in'
                              : isFollowing
                              ? 'Unfollow'
                              : 'Follow',
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                );
              }),
            if (state.hasMore && state.people.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(peopleControllerProvider.notifier)
                              .loadMore(),
                    child: Text(
                      'Load more',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
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
