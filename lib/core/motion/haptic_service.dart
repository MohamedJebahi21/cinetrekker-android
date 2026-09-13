import 'package:flutter/services.dart';

/// Centralized haptic feedback service for CineTrekker.
///
/// Instead of calling [HapticFeedback] directly throughout the app, use these
/// semantic methods so that haptic intensity is consistent and easy to adjust.
abstract final class Haptics {
  // ── Raw intensity levels ───────────────────────────────────────────────────

  /// Barely perceptible tick — used for selection changes.
  static void selection() => HapticFeedback.selectionClick();

  /// Soft tap — default for button presses.
  static void light() => HapticFeedback.lightImpact();

  /// Noticeable thud — for meaningful state changes.
  static void medium() => HapticFeedback.mediumImpact();

  /// Strong pulse — reserved for errors or destructive actions.
  static void heavy() => HapticFeedback.heavyImpact();

  // ── Semantic helpers ───────────────────────────────────────────────────────
  // Use these instead of the raw levels so the intent is clear in code.

  /// Generic button press (BouncyPressable default).
  static void buttonTap() => light();

  /// Bottom navigation bar tab selected.
  static void navigationTap() => selection();

  /// Segmented control / toggle chip changed.
  static void tabSwitch() => selection();

  /// Any on/off toggle changed (grid/list, sort order, etc.).
  static void toggleChange() => selection();

  /// Item added to watchlist.
  static void addToWatchlist() => medium();

  /// Item removed from watchlist.
  static void removeFromWatchlist() => light();

  /// Title marked as watched.
  static void markWatched() => medium();

  /// Title unmarked as watched.
  static void unmarkWatched() => light();

  /// Favorite toggled on.
  static void favorite() => medium();

  /// Favorite toggled off.
  static void unfavorite() => light();

  /// Follow / unfollow a user or show.
  static void follow() => medium();

  /// Season / episode progress changed.
  static void episodeProgress() => light();

  /// Successful operation feedback (share copied, export done, etc.).
  static void success() => medium();

  /// Error or destructive action feedback.
  static void error() => heavy();
}
