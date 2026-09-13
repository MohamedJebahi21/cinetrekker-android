import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/bouncy_pressable.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../shared/widgets/app_error_card.dart';
import 'collections_controller.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collectionsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
    final state = ref.watch(collectionsControllerProvider);
    final notifier = ref.read(collectionsControllerProvider.notifier);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Collections',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: notifier.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _glassCard(theme, isDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Collection',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.dmSans(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Collection name',
                      labelStyle: GoogleFonts.dmSans(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: GoogleFonts.dmSans(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: GoogleFonts.dmSans(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final name = _nameController.text.trim();
                              if (name.isEmpty) return;
                              await notifier.createCollection(
                                name: name,
                                description:
                                    _descriptionController.text.trim().isEmpty
                                    ? null
                                    : _descriptionController.text.trim(),
                              );
                              _nameController.clear();
                              _descriptionController.clear();
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create collection',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (session == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: _glassCard(theme, isDark),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_queue_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Collections are saved on this device. Sign in anytime to sync across devices.',
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
            ],
            const SizedBox(height: 16),
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
                    ref.read(collectionsControllerProvider.notifier).load(),
              ),
            const SizedBox(height: 12),
            if (state.collections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmarks_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No collections yet.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a collection above to organise your titles.',
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
              )
            else
              ...state.collections.map(
                (collection) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BouncyPressable(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: theme.colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (sheetContext) => Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.folder_special_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      collection.name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (collection.description != null &&
                                  collection.description!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  collection.description!,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Text(
                                '${collection.itemCount} titles saved in this collection',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(sheetContext).pop();
                                    context.push('/discover');
                                  },
                                  icon: const Icon(Icons.explore_outlined),
                                  label: const Text('Discover Titles to Add'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.folder_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            collection.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (collection.description != null &&
                                  collection.description!.isNotEmpty)
                                collection.description,
                              '${collection.itemCount} items',
                            ].whereType<String>().join(' · '),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            onPressed: session == null
                                ? () => context.push('/auth')
                                : () => notifier.deleteCollection(collection.id),
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
