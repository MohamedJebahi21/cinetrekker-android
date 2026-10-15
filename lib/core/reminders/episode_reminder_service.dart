import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../models/media_models.dart';
import 'episode_reminder_models.dart';

class EpisodeReminderService {
  EpisodeReminderService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<EpisodeReminderPreference> loadPreferences() async {
    try {
      final raw = await _storage.read(
        key: AppConstants.episodeRemindersStorageKey,
      );
      if (raw == null || raw.trim().isEmpty) {
        return const EpisodeReminderPreference();
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return EpisodeReminderPreference.fromJson(decoded);
      } else if (decoded is Map) {
        return EpisodeReminderPreference.fromJson(
          decoded.cast<String, dynamic>(),
        );
      }
      return const EpisodeReminderPreference();
    } catch (_) {
      return const EpisodeReminderPreference();
    }
  }

  Future<void> savePreferences(EpisodeReminderPreference pref) async {
    final encoded = jsonEncode(pref.toJson());
    await _storage.write(
      key: AppConstants.episodeRemindersStorageKey,
      value: encoded,
    );
  }

  List<EpisodeReminderItem> computeReminders({
    required List<FollowedShowItem> followedShows,
    required EpisodeReminderPreference preferences,
  }) {
    final list = <EpisodeReminderItem>[];

    for (final show in followedShows) {
      if (show.nextAirDate == null || show.nextAirDate!.trim().isEmpty) {
        continue;
      }

      final isEnabled = preferences.isShowEnabled(show.showId);
      final item = EpisodeReminderItem(
        showId: show.showId,
        showName: show.showName ?? 'Show #${show.showId}',
        airDate: show.nextAirDate!.trim(),
        episodeName: show.nextEpisodeName,
        posterPath: show.posterPath,
        isEnabled: isEnabled,
      );

      // Only include upcoming or today episodes
      if (item.isUpcoming) {
        list.add(item);
      }
    }

    // Sort ascending by air date
    list.sort((a, b) {
      final dtA = a.airDateTime ?? DateTime(2100);
      final dtB = b.airDateTime ?? DateTime(2100);
      return dtA.compareTo(dtB);
    });

    return list;
  }

  Future<bool> launchCalendarEvent(
    EpisodeReminderItem item, {
    int reminderHour = 9,
  }) async {
    final uri = item.buildCalendarUri(reminderHour: reminderHour);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
