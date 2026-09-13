import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Version chip ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CineTrekker',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.1 (build 2)',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'About CineTrekker and the connected viewing ecosystem',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          const _PolicyCard(
            title: 'What CineTrekker Is',
            items: [
              'CineTrekker is a personal movie and TV companion for tracking what you want to watch, what you have watched, and how you organize your viewing life.',
              'The Android app is part of a broader CineTrekker ecosystem that can sync with your account across supported platforms.',
            ],
          ),
          const _PolicyCard(
            title: 'Core Features',
            items: [
              'Build and manage watchlists, watched history, episode progress, favorites, and custom collections.',
              'Discover titles, follow shows, and keep your library organized with ratings, filters, and safety preferences.',
              'Connect social activity such as follows and notifications when those features are enabled for your account.',
            ],
          ),
          const _PolicyCard(
            title: 'Designed for Real Viewing Habits',
            items: [
              'CineTrekker focuses on practical tracking rather than replacing your streaming subscriptions.',
              'Accessibility, language, and content-safety controls help tailor the experience to your household and preferences.',
              'Export and deletion tools in Settings give you control over the data stored with your account.',
            ],
          ),
          const _PolicyCard(
            title: 'Data and Sync',
            items: [
              'Signed-in users can sync library data, profile settings, and preferences with CineTrekker backend services.',
              'Guest or offline use may keep some data on-device until you sign in or clear local storage.',
              'Movie and TV metadata is sourced from trusted third-party providers and may update independently of your lists.',
            ],
          ),
          const _PolicyCard(
            title: 'Open Development',
            items: [
              'CineTrekker continues to evolve with improvements to discovery, collections, social features, and cross-device parity.',
              'Feature availability can vary between web and mobile while new capabilities roll out.',
            ],
          ),
          const _PolicyCard(
            title: 'Legal and Support',
            items: [
              'Review the Privacy Policy, Terms of Use, and Cookie Policy from Settings for how data is handled.',
              'Questions, feedback, and support requests can be sent through the CineTrekker website feedback page.',
            ],
          ),
          // ── TMDB Attribution (required by TMDB API Terms of Use) ───────
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Powered by TMDB',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://www.themoviedb.org'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Visit themoviedb.org'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
