import 'dart:ui' show PlatformDispatcher, TextDirection;
import 'package:flutter/semantics.dart';

/// Accessibility announcement helper for TalkBack, VoiceOver and screen readers.
class AppSemantics {
  AppSemantics._();

  /// Announces [message] to active screen readers.
  static void announce(
    String message, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (message.trim().isEmpty) return;
    try {
      final view = PlatformDispatcher.instance.implicitView ??
          PlatformDispatcher.instance.views.firstOrNull;
      if (view != null) {
        SemanticsService.sendAnnouncement(
          view,
          message,
          textDirection,
        );
      }
    } catch (_) {
      // Gracefully no-op if accessibility bridge is not currently active
    }
  }

  /// Announces adding an item to a list or watchlist
  static void announceWatchlistAdd(String title) {
    announce('Added $title to Watchlist');
  }

  /// Announces removing an item from a list or watchlist
  static void announceWatchlistRemove(String title) {
    announce('Removed $title from Watchlist');
  }

  /// Announces favorite changes
  static void announceFavorite({required String title, required bool isFavorite}) {
    announce(
      isFavorite
          ? 'Saved $title to Favorites'
          : 'Removed $title from Favorites',
    );
  }

  /// Announces marking a title as watched with rating
  static void announceRating({required String title, required double rating}) {
    announce('Marked $title as watched with rating ${rating.toStringAsFixed(1)} out of 10');
  }
}
