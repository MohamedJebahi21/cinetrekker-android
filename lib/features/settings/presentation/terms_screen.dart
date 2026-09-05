import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Use',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'CineTrekker terms of use for the mobile app and connected services',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          const _PolicyCard(
            title: 'Acceptance of Terms',
            items: [
              'By installing, signing in to, or using CineTrekker, you agree to these terms and our privacy and cookie policies.',
              'If you do not agree, do not use the app or connected account services.',
            ],
          ),
          const _PolicyCard(
            title: 'What CineTrekker Provides',
            items: [
              'CineTrekker helps you discover, track, and organize movies and TV shows across your watchlist, watched history, collections, and social activity.',
              'The app may sync your library and preferences with your CineTrekker account when you are signed in.',
              'Features may change over time as the product evolves across web and mobile.',
            ],
          ),
          const _PolicyCard(
            title: 'Accounts and Eligibility',
            items: [
              'Some features require a valid CineTrekker account. You are responsible for keeping your sign-in credentials secure.',
              'You must provide accurate account information and promptly update it when it changes.',
              'You may not create accounts for abusive, fraudulent, or automated misuse of the service.',
            ],
          ),
          const _PolicyCard(
            title: 'Acceptable Use',
            items: [
              'Use CineTrekker only for lawful personal or permitted organizational tracking of media content.',
              'Do not attempt to disrupt the service, scrape protected endpoints, bypass safety controls, or harass other users.',
              'Do not upload, share, or promote content that violates applicable law or the rights of others.',
            ],
          ),
          const _PolicyCard(
            title: 'Content and Third-Party Data',
            items: [
              'Movie and TV metadata, artwork, and related information may come from third-party providers and is subject to their terms.',
              'CineTrekker does not host full video streams unless explicitly stated for a specific feature.',
              'Availability, ratings, and metadata may be incomplete or change without notice.',
            ],
          ),
          const _PolicyCard(
            title: 'Your Content and Library Data',
            items: [
              'You retain ownership of the lists, notes, collections, and preferences you create in CineTrekker.',
              'You grant CineTrekker a limited license to store, process, and display that data to operate and improve the service.',
              'You can export or delete your account-linked data using the in-app Settings tools where available.',
            ],
          ),
          const _PolicyCard(
            title: 'Service Availability and Changes',
            items: [
              'CineTrekker is provided on an as-available basis. Maintenance, outages, or provider limits may affect access.',
              'We may add, modify, or remove features to keep the app secure, reliable, and compliant.',
              'We may suspend or terminate access for violations of these terms or to protect users and infrastructure.',
            ],
          ),
          const _PolicyCard(
            title: 'Disclaimers and Liability',
            items: [
              'CineTrekker is provided without warranties of uninterrupted operation or complete accuracy of third-party metadata.',
              'To the extent permitted by law, CineTrekker is not liable for indirect, incidental, or consequential damages arising from use of the app.',
              'Some jurisdictions do not allow certain warranty or liability limitations, so parts of this section may not apply to you.',
            ],
          ),
          const _PolicyCard(
            title: 'Updates and Contact',
            items: [
              'These terms may be updated from time to time. Continued use after changes take effect means you accept the revised terms.',
              'For questions about these terms, contact the CineTrekker team through the website feedback page.',
            ],
          ),
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
