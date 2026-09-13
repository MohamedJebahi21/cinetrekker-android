import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/motion/motion_tokens.dart';
import 'skeleton_loaders.dart';

/// Standardised network image widget for CineTrekker.
///
/// Wraps [CachedNetworkImage] with a consistent loading experience:
///  * Shimmer skeleton placeholder (not a plain solid colour).
///  * Fast 200 ms fade-in (instead of the library default 1000 ms).
///  * Graceful error state with icon.
///  * Respects reduced-motion preference (instant display, no fade).
///
/// Use this everywhere instead of raw [CachedNetworkImage] for a polished,
/// uniform image loading feel across the entire app.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.errorIcon = Icons.image_not_supported_outlined,
    this.errorIconSize = 24,
  });

  /// The URL of the image to load.
  final String imageUrl;

  /// Optional fixed width. Pass `double.infinity` for full-width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// How the image should be inscribed into the box. Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// Border radius applied to both the skeleton placeholder and the loaded
  /// image, ensuring a consistent shape at every stage.
  final BorderRadius borderRadius;

  /// Icon shown when the image fails to load.
  final IconData errorIcon;

  /// Size of the error icon.
  final double errorIconSize;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration:
            reduceMotion ? Duration.zero : MotionTokens.imageFadeIn,
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => AppSkeletonBox(
          width: width,
          height: height ?? 100,
          borderRadius: BorderRadius.zero, // already clipped by parent
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Icon(
              errorIcon,
              size: errorIconSize,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
