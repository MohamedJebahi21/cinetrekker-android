import 'package:flutter/animation.dart';

/// Centralized motion design tokens for CineTrekker.
///
/// All animation durations, easing curves, and scale factors should reference
/// these tokens instead of using hardcoded values. This ensures consistency
/// across the entire app and makes it easy to tune the overall feel.
abstract final class MotionTokens {
  // ── Durations ──────────────────────────────────────────────────────────────

  /// Ultra-quick feedback (haptic-only, icon swap). 100 ms.
  static const Duration micro = Duration(milliseconds: 100);

  /// Fast UI reactions (toggle state, chip highlight). 150 ms.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions (content cross-fade, container morph). 250 ms.
  static const Duration standard = Duration(milliseconds: 250);

  /// Emphasized motion (page transitions, hero). 350 ms.
  static const Duration emphasis = Duration(milliseconds: 350);

  /// Dramatic reveals (score ring fill, onboarding). 500 ms.
  static const Duration dramatic = Duration(milliseconds: 500);

  /// Shimmer loop cycle. 1400 ms.
  static const Duration shimmer = Duration(milliseconds: 1400);

  // ── Easing Curves ──────────────────────────────────────────────────────────

  /// Default deceleration for elements entering the viewport.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Symmetric ease for elements that move and settle.
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Gentle deceleration for fading content.
  static const Curve decelerate = Curves.decelerate;

  // ── Page Transition Durations ──────────────────────────────────────────────

  /// Forward duration for full-screen push transitions (slide + fade).
  static const Duration pageEnter = Duration(milliseconds: 300);

  /// Reverse duration for full-screen pop transitions.
  static const Duration pageExit = Duration(milliseconds: 220);

  /// Forward duration for tab/shell cross-fade transitions.
  static const Duration tabEnter = Duration(milliseconds: 200);

  /// Reverse duration for tab/shell cross-fade transitions.
  static const Duration tabExit = Duration(milliseconds: 150);

  // ── Scale Factors ──────────────────────────────────────────────────────────

  /// Press-down scale for buttons and small interactive elements.
  static const double pressScale = 0.97;

  /// Press-down scale for cards (slightly less aggressive).
  static const double cardPressScale = 0.98;

  // ── Image ──────────────────────────────────────────────────────────────────

  /// Fade-in duration for network images after loading.
  static const Duration imageFadeIn = Duration(milliseconds: 200);

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns [Duration.zero] when animations are disabled, otherwise [d].
  static Duration resolve(Duration d, {required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : d;
}
