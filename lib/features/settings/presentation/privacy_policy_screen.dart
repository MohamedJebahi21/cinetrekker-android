import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const canonicalUrl = 'https://cinetrekker.vercel.app/privacy';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'CineTrekker Privacy Policy',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated: 15 August 2026',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This policy explains what CineTrekker processes, why it is needed, and the controls available to you. The Android app and website use the same CineTrekker account and Supabase project.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),
          const _Section(
            title: 'Information we process',
            body:
                'When you create or use an account, CineTrekker may process your email address, authentication identifiers, profile details, watchlist, watched titles, ratings, collections, comments, follows, notifications, and TV-tracking data. The app may also store session and preference data securely on your device.',
          ),
          const _Section(
            title: 'How we use information',
            body:
                'We use this information to authenticate you, synchronize your account between the website and Android app, provide watchlist and history features, show recommendations and tracking updates, protect the service, and respond to support or deletion requests.',
          ),
          const _Section(
            title: 'Third-party services',
            body:
                'Account and application data are stored and synchronized through Supabase. Movie and television metadata, images, and related information are obtained from The Movie Database (TMDB) and remain subject to their terms and privacy practices. Network traffic is sent over HTTPS.',
          ),
          const _Section(
            title: 'Retention and deletion',
            body:
                'Your account data is retained while your account is active or as needed to provide the service. You can request account deletion from the CineTrekker settings or feedback flow. Deleting an account removes the associated profile and application data where supported by the service, subject to limited operational or legal retention requirements.',
          ),
          const _Section(
            title: 'Your choices',
            body:
                'You can sign out, update profile and content-safety settings, manage your watchlist and history, and request deletion or correction of your information. You may stop using the app at any time; uninstalling it removes local app data but does not by itself delete your online account.',
          ),
          const _Section(
            title: 'Children',
            body:
                'CineTrekker is not directed to children under 13, and we do not knowingly collect personal information from children under 13.',
          ),
          const _Section(
            title: 'Contact and canonical policy',
            body:
                'For questions, privacy requests, or account deletion assistance, use the CineTrekker Feedback page. The current canonical policy is available at:',
          ),
          SelectableText(
            canonicalUrl,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This in-app policy is provided for convenience; the canonical website policy controls if the two versions differ.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

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
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}
