import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/motion/haptic_service.dart';
import 'app_cached_image.dart';

/// Modal dialog displaying a high-resolution 9:16 vertical story card suitable
/// for sharing on Instagram Stories, WhatsApp Status, Telegram, X/Twitter, or saving.
class CinematicShareCardDialog extends StatefulWidget {
  const CinematicShareCardDialog({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.releaseYear,
    this.genres = const [],
    this.userRating,
    this.userReview,
  });

  final int mediaId;
  final String mediaType;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final String? releaseYear;
  final List<String> genres;
  final double? userRating;
  final String? userReview;

  static Future<void> show(
    BuildContext context, {
    required int mediaId,
    required String mediaType,
    required String title,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    String? releaseYear,
    List<String> genres = const [],
    double? userRating,
    String? userReview,
  }) {
    Haptics.buttonTap();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => CinematicShareCardDialog(
        mediaId: mediaId,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        releaseYear: releaseYear,
        genres: genres,
        userRating: userRating,
        userReview: userReview,
      ),
    );
  }

  @override
  State<CinematicShareCardDialog> createState() => _CinematicShareCardDialogState();
}

class _CinematicShareCardDialogState extends State<CinematicShareCardDialog> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  bool _isGeneratingImage = false;

  String get _deepLinkUrl =>
      'https://cinetrekker.vercel.app/${widget.mediaType}/${widget.mediaId}';

  Future<void> _shareCardImage() async {
    setState(() => _isGeneratingImage = true);
    Haptics.buttonTap();

    try {
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Story card render boundary unavailable');
      }

      // Render at 3.0 pixel ratio for crystal clear high-dpi story export
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode card image to PNG');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/cinetrekker_story_$timestamp.png');
      await file.writeAsBytes(pngBytes, flush: true);

      Haptics.success();

      final shareText = widget.userRating != null && widget.userRating! > 0
          ? 'Rated "${widget.title}" ${widget.userRating!.toStringAsFixed(1)} ★ on CineTrekker! $_deepLinkUrl'
          : 'Tracking "${widget.title}" on CineTrekker! $_deepLinkUrl';

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: '${widget.title} on CineTrekker',
        text: shareText,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Graceful fallback to clipboard URL copy if native image intent fails
      await Clipboard.setData(ClipboardData(text: _deepLinkUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not share image ($e). Link copied to clipboard.',
              style: GoogleFonts.dmSans(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Constrain card preview nicely for mobile dialog
    final cardHeight = (size.height * 0.72).clamp(420.0, 620.0);
    final cardWidth = cardHeight * (9.0 / 16.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cinematic 9:16 Story Card',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // The Captured 9:16 Card
          Center(
            child: RepaintBoundary(
              key: _cardBoundaryKey,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Dark slate base
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Backdrop Art
                    if (widget.backdropPath != null)
                      AppCachedImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w780${widget.backdropPath}',
                        fit: BoxFit.cover,
                      )
                    else if (widget.posterPath != null)
                      AppCachedImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w780${widget.posterPath}',
                        fit: BoxFit.cover,
                      ),

                    // Atmospheric Multi-Stop Gradients
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.20),
                            Colors.black.withValues(alpha: 0.75),
                            const Color(0xFF090D16).withValues(alpha: 0.96),
                          ],
                          stops: const [0.0, 0.35, 0.65, 1.0],
                        ),
                      ),
                    ),

                    // Content Layer
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Brand Watermark
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CINETREKKER',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              if (widget.mediaType.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.mediaType.toUpperCase(),
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const Spacer(),

                          // Floating Poster & Info Pill Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.posterPath != null)
                                Container(
                                  width: cardWidth * 0.34,
                                  height: cardWidth * 0.34 * 1.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black87,
                                        blurRadius: 16,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.5),
                                    child: AppCachedImage(
                                      imageUrl:
                                          'https://image.tmdb.org/t/p/w342${widget.posterPath}',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Ratings
                                    if (widget.userRating != null &&
                                        widget.userRating! > 0) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFB800),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Colors.black,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${widget.userRating!.toStringAsFixed(1)} / 10',
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ] else if (widget.voteAverage != null &&
                                        widget.voteAverage! > 0) ...[
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFB800),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.voteAverage!.toStringAsFixed(1),
                                            style: GoogleFonts.spaceGrotesk(
                                              color: const Color(0xFFFFB800),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (widget.releaseYear != null &&
                                              widget.releaseYear!.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              '• ${widget.releaseYear}',
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                    ],

                                    // Title
                                    Text(
                                      widget.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Genre Pills
                          if (widget.genres.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: widget.genres.take(3).map((genre) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Text(
                                    genre,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          // User Review Note
                          if (widget.userReview != null &&
                              widget.userReview!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Text(
                                '"${widget.userReview!.trim()}"',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Bottom Footer Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'cinetrekker.vercel.app',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  'Track movies & TV',
                                  style: GoogleFonts.dmSans(
                                    color: theme.colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isGeneratingImage ? null : _shareCardImage,
                  icon: _isGeneratingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    _isGeneratingImage ? 'Generating...' : 'Share 9:16 Story',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () async {
                  Haptics.buttonTap();
                  await Clipboard.setData(ClipboardData(text: _deepLinkUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Media link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.link_rounded),
                tooltip: 'Copy Link',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
