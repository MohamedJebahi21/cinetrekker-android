import 'package:flutter/material.dart';

import '../../core/motion/motion_tokens.dart';

/// A drop-in replacement for [AnimatedSwitcher] pre-configured with
/// CineTrekker's motion tokens.
///
/// Use this to wrap content that transitions between states (loading → data,
/// empty → filled, tab A → tab B). It cross-fades with a subtle vertical
/// slide so the new content feels like it "settles in" naturally.
///
/// Respects the platform's reduced-motion preference via
/// [MediaQuery.disableAnimations].
class AnimatedContentSwitcher extends StatelessWidget {
  const AnimatedContentSwitcher({
    super.key,
    required this.child,
    this.duration,
    this.alignment = Alignment.topCenter,
  });

  /// The widget to display. When [child] changes (different key), the switcher
  /// cross-fades from the old child to the new one.
  final Widget child;

  /// Override the default transition duration. Defaults to
  /// [MotionTokens.standard] (250 ms).
  final Duration? duration;

  /// Alignment for sizing the transition area. Defaults to [Alignment.topCenter]
  /// so that content doesn't jump when heights differ.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveDuration = reduceMotion
        ? Duration.zero
        : (duration ?? MotionTokens.standard);

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: MotionTokens.easeOut,
      switchOutCurve: MotionTokens.easeOut,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: alignment,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        if (reduceMotion) return child;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: MotionTokens.easeOut,
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
