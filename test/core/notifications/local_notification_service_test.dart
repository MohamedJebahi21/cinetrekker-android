import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrekker_android/core/notifications/local_notification_service.dart';

void main() {
  group('LocalNotificationService helper logic', () {
    test('generateNotificationId produces deterministic positive integers', () {
      final id1 = LocalNotificationService.generateNotificationId(12345);
      final id2 = LocalNotificationService.generateNotificationId(12345);
      final idNeg = LocalNotificationService.generateNotificationId(-9876);

      expect(id1, id2);
      expect(id1, 12345);
      expect(idNeg, 9876);
      expect(id1, isNonNegative);
      expect(id1, lessThan(1000000));
    });

    test('adjustForQuietHours preserves time when quiet hours disabled', () {
      final dt = DateTime(2026, 5, 10, 23, 0);
      final adjusted = LocalNotificationService.adjustForQuietHours(
        dt,
        quietHoursEnabled: false,
        quietHoursStart: 22,
        quietHoursEnd: 8,
      );

      expect(adjusted, dt);
    });

    test('adjustForQuietHours preserves time outside quiet hours', () {
      final dt = DateTime(2026, 5, 10, 14, 0); // 2 PM
      final adjusted = LocalNotificationService.adjustForQuietHours(
        dt,
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 8,
      );

      expect(adjusted.hour, 14);
      expect(adjusted.day, 10);
    });

    test('adjustForQuietHours delays late night alert (e.g. 11 PM) to 8 AM next morning', () {
      final dt = DateTime(2026, 5, 10, 23, 0); // 11 PM
      final adjusted = LocalNotificationService.adjustForQuietHours(
        dt,
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 8,
      );

      expect(adjusted.day, 11);
      expect(adjusted.hour, 8);
      expect(adjusted.minute, 0);
    });

    test('adjustForQuietHours delays early morning alert (e.g. 4 AM) to 8 AM same day', () {
      final dt = DateTime(2026, 5, 10, 4, 0); // 4 AM
      final adjusted = LocalNotificationService.adjustForQuietHours(
        dt,
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 8,
      );

      expect(adjusted.day, 10);
      expect(adjusted.hour, 8);
      expect(adjusted.minute, 0);
    });

    test('calculateScheduledDateTime computes lead timing and reminder hour correctly', () {
      final airDate = DateTime(2026, 6, 20);
      final scheduled = LocalNotificationService.calculateScheduledDateTime(
        airDate: airDate,
        leadDays: 1, // 1 day before
        reminderHour: 9, // 9 AM
        quietHoursEnabled: false,
        quietHoursStart: 22,
        quietHoursEnd: 8,
      );

      expect(scheduled.year, 2026);
      expect(scheduled.month, 6);
      expect(scheduled.day, 19);
      expect(scheduled.hour, 9);
      expect(scheduled.minute, 0);
    });
  });
}
