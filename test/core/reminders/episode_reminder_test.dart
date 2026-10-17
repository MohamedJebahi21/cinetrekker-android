import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrekker_android/core/models/media_models.dart';
import 'package:cinetrekker_android/core/reminders/episode_reminder_service.dart';
import 'package:cinetrekker_android/core/reminders/episode_reminder_controller.dart';

void main() {
  group('EpisodeReminderPreference', () {
    test('default values are enabled with 0 lead days and 9am hour', () {
      const pref = EpisodeReminderPreference();
      expect(pref.enabled, isTrue);
      expect(pref.leadDays, 0);
      expect(pref.reminderHour, 9);
      expect(pref.quietHoursEnabled, isFalse);
      expect(pref.leadDaysLabel, 'On release day');
      expect(pref.isShowEnabled(123), isTrue);
    });

    test('serializes and deserializes cleanly', () {
      const pref = EpisodeReminderPreference(
        enabled: true,
        leadDays: 1,
        reminderHour: 10,
        quietHoursEnabled: true,
        quietHoursStart: 23,
        quietHoursEnd: 7,
        showReminders: {42: false, 99: true},
      );

      final json = pref.toJson();
      final reconstructed = EpisodeReminderPreference.fromJson(json);

      expect(reconstructed.enabled, isTrue);
      expect(reconstructed.leadDays, 1);
      expect(reconstructed.reminderHour, 10);
      expect(reconstructed.quietHoursEnabled, isTrue);
      expect(reconstructed.quietHoursStart, 23);
      expect(reconstructed.quietHoursEnd, 7);
      expect(reconstructed.isShowEnabled(42), isFalse);
      expect(reconstructed.isShowEnabled(99), isTrue);
      expect(reconstructed.isShowEnabled(100), isTrue);
      expect(reconstructed.leadDaysLabel, '1 day before');
    });

    test('copyWith updates fields as expected', () {
      const original = EpisodeReminderPreference();
      final updated = original.copyWith(
        enabled: false,
        leadDays: 2,
        reminderHour: 18,
      );

      expect(updated.enabled, isFalse);
      expect(updated.leadDays, 2);
      expect(updated.reminderHour, 18);
      expect(updated.leadDaysLabel, '2 days before');
      expect(updated.isShowEnabled(123), isFalse); // master switch disabled
    });
  });

  group('EpisodeReminderItem', () {
    test('calculates relative dates and isUpcoming correctly', () {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final futureDate = now.add(const Duration(days: 3));
      final futureStr = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      final pastDate = now.subtract(const Duration(days: 2));
      final pastStr = '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}';

      final todayItem = EpisodeReminderItem(
        showId: 1,
        showName: 'Show Today',
        airDate: todayStr,
      );
      final futureItem = EpisodeReminderItem(
        showId: 2,
        showName: 'Show Future',
        airDate: futureStr,
      );
      final pastItem = EpisodeReminderItem(
        showId: 3,
        showName: 'Show Past',
        airDate: pastStr,
      );

      expect(todayItem.isToday, isTrue);
      expect(todayItem.isUpcoming, isTrue);
      expect(todayItem.relativeDateLabel, 'Today');

      expect(futureItem.isToday, isFalse);
      expect(futureItem.isUpcoming, isTrue);
      expect(futureItem.relativeDateLabel, 'In 3 days');

      expect(pastItem.isUpcoming, isFalse);
      expect(pastItem.relativeDateLabel, '2d ago');
    });

    test('buildCalendarUri creates valid Google Calendar link', () {
      const item = EpisodeReminderItem(
        showId: 100,
        showName: 'Severance',
        airDate: '2026-10-15',
        episodeName: 'S2 E1 "Hello"',
      );

      final uri = item.buildCalendarUri(reminderHour: 9);

      expect(uri.scheme, 'https');
      expect(uri.host, 'calendar.google.com');
      expect(uri.path, '/calendar/render');
      expect(uri.queryParameters['action'], 'TEMPLATE');
      expect(uri.queryParameters['text'], contains('Severance'));
      expect(uri.queryParameters['text'], contains('S2 E1'));
      expect(uri.queryParameters['details'], contains('2026-10-15'));
      expect(uri.queryParameters['details'], contains('CineTrekker'));
    });
  });

  group('EpisodeReminderService.computeReminders', () {
    test('filters missing air dates and past air dates, respects overrides and sorts ascending', () {
      final service = EpisodeReminderService();
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final nextWeek = now.add(const Duration(days: 7));
      final past = now.subtract(const Duration(days: 5));

      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final shows = <FollowedShowItem>[
        FollowedShowItem(
          showId: 1,
          userId: 'u1',
          showName: 'Later Show',
          nextAirDate: fmt(nextWeek),
        ),
        FollowedShowItem(
          showId: 2,
          userId: 'u1',
          showName: 'Tomorrow Show',
          nextAirDate: fmt(tomorrow),
        ),
        FollowedShowItem(
          showId: 3,
          userId: 'u1',
          showName: 'Past Show',
          nextAirDate: fmt(past),
        ),
        const FollowedShowItem(
          showId: 4,
          userId: 'u1',
          showName: 'No Air Date Show',
          nextAirDate: null,
        ),
      ];

      const pref = EpisodeReminderPreference(
        showReminders: {1: false}, // Show 1 is muted
      );

      final reminders = service.computeReminders(
        followedShows: shows,
        preferences: pref,
      );

      // Only 2 upcoming shows (Tomorrow Show and Later Show)
      expect(reminders.length, 2);
      // Ascending order: Tomorrow Show first
      expect(reminders[0].showId, 2);
      expect(reminders[0].showName, 'Tomorrow Show');
      expect(reminders[0].isEnabled, isTrue);

      expect(reminders[1].showId, 1);
      expect(reminders[1].showName, 'Later Show');
      expect(reminders[1].isEnabled, isFalse); // muted via showReminders
    });
  });

  group('EpisodeReminderState', () {
    test('activeReminders only returns enabled and upcoming items', () {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 2));
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final itemEnabled = EpisodeReminderItem(
        showId: 10,
        showName: 'Active Show',
        airDate: fmt(future),
        isEnabled: true,
      );
      final itemMuted = EpisodeReminderItem(
        showId: 20,
        showName: 'Muted Show',
        airDate: fmt(future),
        isEnabled: false,
      );

      final state = EpisodeReminderState(
        preferences: const EpisodeReminderPreference(
          showReminders: {20: false},
        ),
        reminders: [itemEnabled, itemMuted],
      );

      expect(state.activeCount, 1);
      expect(state.activeReminders.first.showId, 10);
      expect(state.isShowReminded(10), isTrue);
      expect(state.isShowReminded(20), isFalse);
    });
  });
}
