import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/accessibility/text_scale_controller.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/content_safety/content_safety_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/motion/haptic_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../collections/data/collections_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../social/data/social_repository.dart';
import '../../watchlist/data/user_library_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _maturityRating = 'none';
  bool _showAge = false;
  bool _adultContentEnabled = false;
  bool _strictFilteringEnabled = true;
  bool _moderateFilteringEnabled = false;
  bool _loadedFromProfile = false;
  String? _syncedSafetySignature;
  bool _isExportingData = false;
  bool _isDeletingData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  void _syncFromProfile(UserProfileData? profile) {
    if (profile == null || _loadedFromProfile) {
      return;
    }

    _maturityRating = profile.maturityRating;
    _showAge = profile.showAge;
    _adultContentEnabled = profile.adultContentEnabled;
    _strictFilteringEnabled = profile.strictFilteringEnabled;
    _moderateFilteringEnabled = profile.moderateFilteringEnabled;
    _loadedFromProfile = true;
  }

  void _syncFromSafety(CineTrekkerContentSafety safety) {
    final signature =
        '${safety.maturityRating}:${safety.showAge}:${safety.adultContentEnabled}:${safety.strictFilteringEnabled}:${safety.moderateFilteringEnabled}';
    if (_syncedSafetySignature == signature) {
      return;
    }

    _maturityRating = safety.maturityRating;
    _showAge = safety.showAge;
    _adultContentEnabled = safety.adultContentEnabled;
    _strictFilteringEnabled = safety.strictFilteringEnabled;
    _moderateFilteringEnabled = safety.moderateFilteringEnabled;
    _syncedSafetySignature = signature;
  }

  Future<Map<String, dynamic>> _buildExportPayload({
    required String themeMode,
    required String textScaleMode,
    required double fontSizeScale,
  }) async {
    final authState = ref.read(authControllerProvider);
    final session = authState.valueOrNull;
    final profileRepo = ref.read(profileRepositoryProvider);
    final collectionsRepo = ref.read(collectionsRepositoryProvider);
    final socialRepo = ref.read(socialRepositoryProvider);
    final libraryRepo = ref.read(userLibraryRepositoryProvider);
    final safetyState = ref.read(contentSafetyControllerProvider);
    final profileState = ref.read(profileControllerProvider);
    final profile =
        profileState.profile ??
        (profileRepo == null ? null : await profileRepo.loadProfile());

    final watchlist = await libraryRepo.getWatchlist();
    final watched = await libraryRepo.getWatched();
    final followedShows = await libraryRepo.getFollowedShows();
    final watchedEpisodes = await libraryRepo.getWatchedEpisodes();
    final collections = await collectionsRepo.loadCollections();
    final notifications = await socialRepo.getNotifications();

    return <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'CineTrekker',
      'version': 'settings-export-v1',
      'account': session == null
          ? <String, dynamic>{'userId': 'guest', 'email': null}
          : <String, dynamic>{
              'userId': session.user.id,
              'email': session.user.email,
            },
      'settings': <String, dynamic>{
        'theme': themeMode,
        'textScale': textScaleMode,
        'fontSizeScale': fontSizeScale,
      },
      'profile': profile?.toJson(session?.user.id ?? ''),
      'contentSafety': <String, dynamic>{
        'maturityRating': profile?.maturityRating ?? safetyState.maturityRating,
        'showAge': profile?.showAge ?? safetyState.showAge,
        'adultContentEnabled':
            profile?.adultContentEnabled ?? safetyState.adultContentEnabled,
        'strictFilteringEnabled':
            profile?.strictFilteringEnabled ??
            safetyState.strictFilteringEnabled,
        'moderateFilteringEnabled':
            profile?.moderateFilteringEnabled ??
            safetyState.moderateFilteringEnabled,
      },
      'watchlist': watchlist
          .map((item) => item.toJson())
          .toList(growable: false),
      'watched': watched.map((item) => item.toJson()).toList(growable: false),
      'followedShows': followedShows
          .map((item) => item.toJson())
          .toList(growable: false),
      'watchedEpisodes': watchedEpisodes
          .map((item) => item.toJson())
          .toList(growable: false),
      'collections': collections
          .map(
            (collection) => <String, dynamic>{
              'id': collection.id,
              'name': collection.name,
              'description': collection.description,
              'itemCount': collection.itemCount,
              'createdAt': collection.createdAt,
              'updatedAt': collection.updatedAt,
            },
          )
          .toList(growable: false),
      'notifications': notifications
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'type': item.type,
              'message': item.message,
              'movieId': item.movieId,
              'isRead': item.isRead,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'favorites': profile?.favoriteTitles ?? const <String>[],
      'hiddenRecommendations': const <dynamic>[],
    };
  }

  Future<void> _showExportDataDialog() async {
    setState(() => _isExportingData = true);
    try {
      final themeStyle = ref.read(themeControllerProvider);
      final textScaleStyle = ref.read(textScaleControllerProvider);
      final fontSizeScale = ref.read(fontSizeScaleControllerProvider);
      final payload = await _buildExportPayload(
        themeMode: themeStyle.name,
        textScaleMode: textScaleStyle.name,
        fontSizeScale: fontSizeScale,
      );
      final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

      if (!mounted) {
        return;
      }

      final scaffoldMessenger = ScaffoldMessenger.of(this.context);

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Export data',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonString,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: jsonString));
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Export copied to clipboard.',
                          style: GoogleFonts.dmSans(),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  'Copy JSON',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not generate export: $error',
              style: GoogleFonts.dmSans(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingData = false);
      }
    }
  }

  Future<void> _deleteAccountData() async {
    setState(() => _isDeletingData = true);
    try {
      final authState = ref.read(authControllerProvider);
      final session = authState.valueOrNull;
      final libraryRepo = ref.read(userLibraryRepositoryProvider);
      final profileRepo = ref.read(profileRepositoryProvider);
      final collectionsRepo = ref.read(collectionsRepositoryProvider);
      final socialRepo = ref.read(socialRepositoryProvider);
      final safetyNotifier = ref.read(contentSafetyControllerProvider.notifier);

      await libraryRepo.clearLocalData();
      await safetyNotifier.clearPreferences();

      if (session != null) {
        await Future.wait<void>([
          profileRepo?.deleteProfile() ?? Future<void>.value(),
          collectionsRepo.deleteAccountData(),
          socialRepo.deleteAccountData(),
          libraryRepo.deleteAccountData(),
        ]);
        await ref.read(authControllerProvider.notifier).signOut();
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session == null
                ? 'This device data was cleared.'
                : 'Your account data was deleted.',
            style: GoogleFonts.dmSans(),
          ),
        ),
      );

      if (session != null) {
        context.go('/auth');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deletion failed: $error',
              style: GoogleFonts.dmSans(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingData = false);
      }
    }
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
    final ref = this.ref;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeStyle = ref.watch(themeControllerProvider);
    final textScaleStyle = ref.watch(textScaleControllerProvider);
    final fontSizeScale = ref.watch(fontSizeScaleControllerProvider);
    final localeStyle = ref.watch(localeControllerProvider);
    final safetyState = ref.watch(contentSafetyControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final session = authState.valueOrNull;
    final notifier = ref.read(authControllerProvider.notifier);
    final themeNotifier = ref.read(themeControllerProvider.notifier);
    final textScaleNotifier = ref.read(textScaleControllerProvider.notifier);
    final fontSizeScaleNotifier = ref.read(fontSizeScaleControllerProvider.notifier);
    final localeNotifier = ref.read(localeControllerProvider.notifier);
    final safetyNotifier = ref.read(contentSafetyControllerProvider.notifier);
    final profileState = ref.watch(profileControllerProvider);
    final profileNotifier = ref.read(profileControllerProvider.notifier);
    _syncFromProfile(profileState.profile);
    _syncFromSafety(safetyState);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Theme
          Text(
            'Theme',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              children:
                  [
                    CineTrekkerThemeStyle.system,
                    CineTrekkerThemeStyle.light,
                    CineTrekkerThemeStyle.dark,
                    CineTrekkerThemeStyle.oled,
                  ].map((style) {
                    final isActive = themeStyle == style;
                    final label = switch (style) {
                      CineTrekkerThemeStyle.system => 'System',
                      CineTrekkerThemeStyle.light => 'Light',
                      CineTrekkerThemeStyle.dark => 'Dark',
                      CineTrekkerThemeStyle.oled => 'OLED',
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Haptics.toggleChange();
                          themeNotifier.setTheme(style);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark
                                      ? theme.cardTheme.color
                                      : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.08),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Language
          Text(
            'Language',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<CineTrekkerLocaleStyle>(
            initialValue: localeStyle,
            style: GoogleFonts.dmSans(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: 'App language',
              labelStyle: GoogleFonts.dmSans(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            items:
                [
                  (CineTrekkerLocaleStyle.system, 'System'),
                  (CineTrekkerLocaleStyle.en, 'English'),
                  (CineTrekkerLocaleStyle.ar, 'Arabic'),
                  (CineTrekkerLocaleStyle.fr, 'French'),
                  (CineTrekkerLocaleStyle.es, 'Spanish'),
                  (CineTrekkerLocaleStyle.de, 'German'),
                  (CineTrekkerLocaleStyle.tr, 'Turkish'),
                ].map((entry) {
                  return DropdownMenuItem(
                    value: entry.$1,
                    child: Text(
                      entry.$2,
                      style: GoogleFonts.dmSans(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                localeNotifier.setLocale(value);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Arabic switches the app into right-to-left layout.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Accessibility
          Semantics(
            header: true,
            child: Text(
              'Accessibility',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Presets
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                (CineTrekkerTextScaleStyle.system, 'System', 1.0),
                (CineTrekkerTextScaleStyle.large, 'Large', 1.15),
                (CineTrekkerTextScaleStyle.xLarge, 'Extra Large', 1.30),
              ].map((entry) {
                final style = entry.$1;
                final label = entry.$2;
                final targetScale = entry.$3;
                final isActive = (fontSizeScale - targetScale).abs() < 0.03 ||
                    (fontSizeScale == 1.0 && textScaleStyle == style);

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: isActive,
                    label: '$label font preset (${(targetScale * 100).round()}%)',
                    child: GestureDetector(
                      onTap: () {
                        Haptics.toggleChange();
                        textScaleNotifier.setScale(style);
                        fontSizeScaleNotifier.setScale(targetScale);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDark
                                  ? theme.cardTheme.color
                                  : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.55,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Continuous Slider Card (0.85× - 1.30×)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _glassCard(theme, isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_size_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Font Size Scaling',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(fontSizeScale * 100).round()}% (${fontSizeScale.toStringAsFixed(2)}×)',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        if ((fontSizeScale - 1.0).abs() > 0.01) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              Haptics.light();
                              fontSizeScaleNotifier.reset();
                              textScaleNotifier.setScale(CineTrekkerTextScaleStyle.system);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                'Reset',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Font size scale slider',
                  value: '${(fontSizeScale * 100).round()} percent',
                  increasedValue: '${((fontSizeScale + 0.05).clamp(0.85, 1.30) * 100).round()} percent',
                  decreasedValue: '${((fontSizeScale - 0.05).clamp(0.85, 1.30) * 100).round()} percent',
                  child: Slider(
                    value: fontSizeScale.clamp(0.85, 1.30),
                    min: 0.85,
                    max: 1.30,
                    divisions: 9,
                    label: '${(fontSizeScale * 100).round()}%',
                    onChanged: (newVal) {
                      final rounded = (newVal * 100).round() / 100.0;
                      if ((rounded - fontSizeScale).abs() > 0.02) {
                        Haptics.selection();
                      }
                      fontSizeScaleNotifier.setScale(rounded);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0.85× Compact',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                        ),
                      ),
                      Text(
                        '1.00× Normal',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: (fontSizeScale - 1.0).abs() < 0.02
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: (fontSizeScale - 1.0).abs() < 0.02
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.50),
                        ),
                      ),
                      Text(
                        '1.30× Large',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Live sample preview box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                        : theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(fontSizeScale),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LIVE PREVIEW',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Interstellar (2014)',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            height: 1.35,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Account
          Text(
            'Account',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _glassCard(theme, isDark),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session?.user.displayName ?? 'Not signed in',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session?.user.email ?? 'No active session',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (session != null)
            FilledButton.icon(
              onPressed: authState.isLoading ? null : () => notifier.signOut(),
              icon: authState.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'Sign out',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: () => context.push('/auth'),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(
                'Sign in to CineTrekker',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Section: Data & Privacy
          Text(
            'Data & privacy',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _glassCard(theme, isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export your profile, lists, watch history, collections, and settings as JSON.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isExportingData ? null : _showExportDataDialog,
                  icon: _isExportingData
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    _isExportingData ? 'Preparing export...' : 'Export data',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/privacy'),
                      child: Text(
                        'Privacy policy',
                        style: GoogleFonts.dmSans(),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/feedback'),
                      child: Text('Feedback', style: GoogleFonts.dmSans()),
                    ),
                    TextButton(
                      onPressed: () => context.push('/terms'),
                      child: Text('Terms of use', style: GoogleFonts.dmSans()),
                    ),
                    TextButton(
                      onPressed: () => context.push('/about'),
                      child: Text('About', style: GoogleFonts.dmSans()),
                    ),
                    TextButton(
                      onPressed: () => context.push('/cookies'),
                      child: Text('Cookie policy', style: GoogleFonts.dmSans()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isDeletingData
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                'Are you sure?',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Text(
                                'This permanently removes your profile, watchlist, watch history, and data. This cannot be undone.',
                                style: GoogleFonts.dmSans(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.dmSans(),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.dmSans(),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            await _deleteAccountData();
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: theme.colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  icon: _isDeletingData
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    ref.watch(authControllerProvider).valueOrNull == null
                        ? 'Clear this device'
                        : 'Delete account data',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Privacy & Safety
          Text(
            'Privacy & safety',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _glassCard(theme, isDark),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                  DropdownButtonFormField<String>(
                    initialValue: _maturityRating,
                    style: GoogleFonts.dmSans(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Maturity rating',
                      labelStyle: GoogleFonts.dmSans(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None')),
                      DropdownMenuItem(value: 'g', child: Text('G')),
                      DropdownMenuItem(value: 'pg', child: Text('PG')),
                      DropdownMenuItem(value: 'pg13', child: Text('PG-13')),
                      DropdownMenuItem(value: 'r', child: Text('R')),
                      DropdownMenuItem(value: 'nc17', child: Text('NC-17')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _maturityRating = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _showAge,
                    onChanged: (value) => setState(() => _showAge = value),
                    activeThumbColor: theme.colorScheme.primary,
                    title: Text(
                      'Show age on profile',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _adultContentEnabled,
                    onChanged: (value) =>
                        setState(() => _adultContentEnabled = value),
                    activeThumbColor: theme.colorScheme.primary,
                    title: Text(
                      'Allow adult content',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _strictFilteringEnabled,
                    onChanged: (value) =>
                        setState(() => _strictFilteringEnabled = value),
                    activeThumbColor: theme.colorScheme.primary,
                    title: Text(
                      'Strict filtering',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _moderateFilteringEnabled,
                    onChanged: (value) =>
                        setState(() => _moderateFilteringEnabled = value),
                    activeThumbColor: theme.colorScheme.primary,
                    title: Text(
                      'Moderate filtering',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: profileState.isLoading
                          ? null
                          : () async {
                              final updatedSafety = CineTrekkerContentSafety(
                                maturityRating: _maturityRating,
                                showAge: _showAge,
                                adultContentEnabled: _adultContentEnabled,
                                strictFilteringEnabled: _strictFilteringEnabled,
                                moderateFilteringEnabled:
                                    _moderateFilteringEnabled,
                              );

                              await safetyNotifier.setPreferences(
                                updatedSafety,
                              );

                              if (session != null) {
                                final profile =
                                    profileState.profile ??
                                    UserProfileData(
                                      userId: session.user.id,
                                      displayName: null,
                                      bio: null,
                                      avatarUrl: session.user.avatarUrl,
                                      isPublic: false,
                                      showWatchlist: true,
                                      showStats: true,
                                      allowRecommendations: true,
                                      showAge: false,
                                      favoriteGenres: const <int>[],
                                      favoriteTitles: const <String>[],
                                      maturityRating: 'none',
                                      adultContentEnabled: false,
                                      strictFilteringEnabled: true,
                                      moderateFilteringEnabled: false,
                                      createdAt: null,
                                      updatedAt: null,
                                    );

                                await profileNotifier.saveProfile(
                                  profile.copyWith(
                                    maturityRating: _maturityRating,
                                    showAge: _showAge,
                                    adultContentEnabled: _adultContentEnabled,
                                    strictFilteringEnabled:
                                        _strictFilteringEnabled,
                                    moderateFilteringEnabled:
                                        _moderateFilteringEnabled,
                                  ),
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save safety settings',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
