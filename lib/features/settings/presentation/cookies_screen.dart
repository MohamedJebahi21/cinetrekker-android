import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CookiesScreen extends StatelessWidget {
  const CookiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cookie Policy',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'How CineTrekker uses cookies, local storage, and similar technologies',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          const _PolicyCard(
            title: 'Why Local Storage Is Used',
            items: [
              'CineTrekker stores information on your device so the app can stay signed in, remember preferences, and load your library quickly.',
              'On mobile, this works through secure local storage and session mechanisms rather than traditional browser cookies.',
            ],
          ),
          const _PolicyCard(
            title: 'Essential Storage',
            items: [
              'Authentication session tokens and account state needed to keep you signed in.',
              'Security-related values used to protect forms, API requests, and abuse-prevention checks.',
              'Cached library data and sync state so watchlists, watched history, and collections remain available between launches.',
            ],
          ),
          const _PolicyCard(
            title: 'Preference Storage',
            items: [
              'Theme mode, language selection, text scale, and accessibility settings.',
              'Content-safety choices such as maturity rating and filtering preferences.',
              'Consent or notice state for optional features when those controls are shown in the app.',
            ],
          ),
          const _PolicyCard(
            title: 'Performance and Reliability',
            items: [
              'Short-lived caches for metadata, images, and recently viewed screens to reduce load times.',
              'Temporary values that help the app recover gracefully after network interruptions or app restarts.',
            ],
          ),
          const _PolicyCard(
            title: 'Optional Analytics',
            items: [
              'When enabled, CineTrekker or its providers may use limited analytics or monitoring technologies to understand crashes, performance, and feature usage.',
              'Optional tracking can be reviewed and adjusted from in-app settings when those controls are available.',
            ],
          ),
          const _PolicyCard(
            title: 'Third-Party Technologies',
            items: [
              'Authentication, metadata, and infrastructure providers may set or process their own session or storage mechanisms as part of delivering the service.',
              'Those providers are used only to operate core app functionality and are subject to their own policies.',
            ],
          ),
          const _PolicyCard(
            title: 'Your Choices',
            items: [
              'You can clear on-device app data from system settings or by using the in-app data deletion tools in Settings.',
              'Signing out removes active session state from the device while account-linked data remains on the backend until you delete it.',
              'Disabling optional analytics, where offered, limits non-essential measurement on future app use.',
            ],
          ),
          const _PolicyCard(
            title: 'More Information',
            items: [
              'For broader data-handling details, see the Privacy Policy and Terms of Use in Settings.',
              'Contact the CineTrekker team through the website feedback page if you have questions about storage or consent.',
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
