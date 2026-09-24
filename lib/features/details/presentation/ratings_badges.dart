import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/enrichment_api_service.dart';
import '../../../core/models/media_models.dart';

class RatingsBadges extends ConsumerWidget {
  const RatingsBadges({
    super.key,
    required this.imdbId,
    this.isTv = false,
  });

  final String? imdbId;
  final bool isTv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedId = imdbId;
    if (resolvedId == null || resolvedId.isEmpty) {
      return const SizedBox.shrink();
    }

    final ratingsAsync = ref.watch(enrichedRatingsProvider(resolvedId));
    final scheduleAsync = isTv
        ? ref.watch(tvScheduleProvider(resolvedId))
        : const AsyncValue<TVSchedule?>.data(null);

    final ratings = ratingsAsync.asData?.value;
    final schedule = scheduleAsync.asData?.value;

    final hasRatings = ratings != null && ratings.hasAnyRating;
    final hasSchedule = schedule != null && schedule.hasSchedule;

    if (!hasRatings && !hasSchedule) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (hasRatings) ...<Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              // Rotten Tomatoes
              if (ratings.rottenTomatoes != null &&
                  ratings.rottenTomatoes!.isNotEmpty)
                _buildBadge(
                  context,
                  iconText: '🍅',
                  text: '${ratings.rottenTomatoes} Rotten Tomatoes',
                  borderColor: const Color(0x66EF4444),
                  bgColor: const Color(0x337F1D1D),
                  textColor: const Color(0xFFFCA5A5),
                ),

              // Metascore
              if (ratings.metascore != null && ratings.metascore!.isNotEmpty)
                _buildBadge(
                  context,
                  iconText: 'Ⓜ️',
                  text: '${ratings.metascore} Metascore',
                  borderColor: const Color(0x6610B981),
                  bgColor: const Color(0x33064E3B),
                  textColor: const Color(0xFF6EE7B7),
                ),

              // IMDb
              if (ratings.imdbRating != null && ratings.imdbRating!.isNotEmpty)
                _buildBadge(
                  context,
                  icon: const Icon(
                    Icons.star,
                    size: 14,
                    color: Color(0xFFFBBF24),
                  ),
                  text: '${ratings.imdbRating}/10 IMDb',
                  borderColor: const Color(0x66F59E0B),
                  bgColor: const Color(0x3378350F),
                  textColor: const Color(0xFFFCD34D),
                ),

              // Box Office
              if (ratings.boxOffice != null && ratings.boxOffice!.isNotEmpty)
                _buildBadge(
                  context,
                  icon: const Icon(
                    Icons.attach_money,
                    size: 14,
                    color: Color(0xFF34D399),
                  ),
                  text: ratings.boxOffice!,
                  borderColor: Colors.white12,
                  bgColor: Colors.black26,
                  textColor: Colors.white70,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // TV Schedule (TVMaze)
        if (hasSchedule) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.tv,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatScheduleText(schedule),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    String? iconText,
    Widget? icon,
    required String text,
    required Color borderColor,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (iconText != null) ...<Widget>[
            Text(iconText, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
          ] else if (icon != null) ...<Widget>[
            icon,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatScheduleText(TVSchedule schedule) {
    final buffer = StringBuffer();
    if (schedule.network != null && schedule.network!.isNotEmpty) {
      buffer.write('${schedule.network} • ');
    }
    if (schedule.days.isNotEmpty && schedule.time != null) {
      buffer.write('${schedule.days.join(", ")} at ${schedule.time}');
    }
    if (schedule.nextEpisode != null) {
      final ep = schedule.nextEpisode!;
      if (buffer.isNotEmpty) buffer.write(' | ');
      buffer.write('Next: S${ep.season}E${ep.number} "${ep.name}" (${ep.airdate})');
    }
    return buffer.toString();
  }
}
