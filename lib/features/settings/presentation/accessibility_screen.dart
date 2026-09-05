import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/accessibility/reduced_motion_controller.dart';
import '../../../core/accessibility/text_scale_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';

class AccessibilityScreen extends ConsumerWidget {
  const AccessibilityScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final themeStyle = ref.watch(themeControllerProvider);
    final localeStyle = ref.watch(localeControllerProvider);
    final textScaleStyle = ref.watch(textScaleControllerProvider);
    final motionStyle = ref.watch(reducedMotionControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accessibility',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Make CineTrekker work for you.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust the visual experience and motion preferences. These choices are saved on this device.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 24),

          // Theme card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _glassCard(theme, isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the appearance that is easiest to read.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                  ),
                ),
                const SizedBox(height: 12),
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
                              onTap: () => ref
                                  .read(themeControllerProvider.notifier)
                                  .setTheme(style),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
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
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Text size card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _glassCard(theme, isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Text size',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Increase text size without changing your device settings.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                  ),
                ),
                const SizedBox(height: 12),
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
                          CineTrekkerTextScaleStyle.system,
                          CineTrekkerTextScaleStyle.large,
                          CineTrekkerTextScaleStyle.xLarge,
                        ].map((style) {
                          final isActive = textScaleStyle == style;
                          final label = switch (style) {
                            CineTrekkerTextScaleStyle.system => 'System',
                            CineTrekkerTextScaleStyle.large => 'Large',
                            CineTrekkerTextScaleStyle.xLarge => 'Extra Large',
                          };
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(textScaleControllerProvider.notifier)
                                  .setScale(style),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
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
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Language card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _glassCard(theme, isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the language used for the interface and movie data.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CineTrekkerLocaleStyle>(
                  initialValue: localeStyle,
                  style: GoogleFonts.dmSans(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.translate_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  items:
                      [
                        (CineTrekkerLocaleStyle.system, 'System default'),
                        (CineTrekkerLocaleStyle.en, 'English'),
                        (CineTrekkerLocaleStyle.ar, 'العربية'),
                        (CineTrekkerLocaleStyle.fr, 'Français'),
                        (CineTrekkerLocaleStyle.de, 'Deutsch'),
                        (CineTrekkerLocaleStyle.es, 'Español'),
                        (CineTrekkerLocaleStyle.tr, 'Türkçe'),
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
                      ref
                          .read(localeControllerProvider.notifier)
                          .setLocale(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Reduce motion card
          Container(
            decoration: _glassCard(theme, isDark),
            child: SwitchListTile.adaptive(
              value: motionStyle == CineTrekkerMotionStyle.reduced,
              onChanged: (value) => ref
                  .read(reducedMotionControllerProvider.notifier)
                  .setStyle(
                    value
                        ? CineTrekkerMotionStyle.reduced
                        : CineTrekkerMotionStyle.full,
                  ),
              activeThumbColor: theme.colorScheme.primary,
              secondary: Icon(
                Icons.motion_photos_off_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Reduce motion',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Use simpler transitions and minimize animation.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Built-in accessibility',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeatureRow(
                  icon: Icons.keyboard_alt_outlined,
                  text:
                      'Controls use standard Android semantics and keyboard focus behavior.',
                ),
                _FeatureRow(
                  icon: Icons.image_outlined,
                  text:
                      'Images include descriptive labels where the content is meaningful.',
                ),
                _FeatureRow(
                  icon: Icons.touch_app_outlined,
                  text:
                      'Interactive controls provide clear labels, states, and loading feedback.',
                ),
                _FeatureRow(
                  icon: Icons.sync_outlined,
                  text:
                      'Your preferences are stored locally and do not change your shared account data.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await ref
                  .read(themeControllerProvider.notifier)
                  .setTheme(CineTrekkerThemeStyle.system);
              await ref
                  .read(textScaleControllerProvider.notifier)
                  .setScale(CineTrekkerTextScaleStyle.system);
              await ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(CineTrekkerLocaleStyle.system);
              await ref
                  .read(reducedMotionControllerProvider.notifier)
                  .setStyle(CineTrekkerMotionStyle.full);
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(
              'Reset accessibility settings',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
