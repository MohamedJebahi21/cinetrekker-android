import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../reminders/episode_reminder_models.dart';

/// Service responsible for managing native operating system notifications
/// on Android (and cross-platform fallbacks) for upcoming TV episodes.
class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final LocalNotificationService instance = LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String episodeChannelId = 'episode_releases';
  static const String episodeChannelName = 'Episode & Release Reminders';
  static const String episodeChannelDesc =
      'Alerts for upcoming episodes and season releases of tracked TV series';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void Function(String? payload)? onNotificationTapped;
  String? _pendingRoute;
  String? get pendingRoute => _pendingRoute;

  /// Generates a deterministic notification ID for a given showId.
  static int generateNotificationId(int showId) => showId.abs() % 1000000;

  /// Adjusts a scheduled DateTime if it falls within configured quiet hours.
  static DateTime adjustForQuietHours(
    DateTime scheduled, {
    required bool quietHoursEnabled,
    required int quietHoursStart,
    required int quietHoursEnd,
  }) {
    if (!quietHoursEnabled) return scheduled;

    final hour = scheduled.hour;
    final isQuiet = quietHoursStart > quietHoursEnd
        ? (hour >= quietHoursStart || hour < quietHoursEnd)
        : (hour >= quietHoursStart && hour < quietHoursEnd);

    if (!isQuiet) return scheduled;

    // Push forward to the quietHoursEnd hour
    if (quietHoursStart > quietHoursEnd && hour >= quietHoursStart) {
      // Advance to tomorrow at quietHoursEnd
      final tomorrow = scheduled.add(const Duration(days: 1));
      return DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        quietHoursEnd,
        0,
      );
    } else {
      // Same day at quietHoursEnd
      return DateTime(
        scheduled.year,
        scheduled.month,
        scheduled.day,
        quietHoursEnd,
        0,
      );
    }
  }

  /// Calculates the exact scheduled target DateTime given release air date and preferences.
  static DateTime calculateScheduledDateTime({
    required DateTime airDate,
    required int leadDays,
    required int reminderHour,
    required bool quietHoursEnabled,
    required int quietHoursStart,
    required int quietHoursEnd,
  }) {
    final baseDate = airDate.subtract(Duration(days: leadDays));
    final initial = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      reminderHour,
      0,
    );
    return adjustForQuietHours(
      initial,
      quietHoursEnabled: quietHoursEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
    );
  }

  /// Initializes the local notification plugin and configures Android notification channels.
  Future<bool> initialize({
    void Function(String? payload)? onSelectNotification,
  }) async {
    if (onSelectNotification != null) {
      onNotificationTapped = onSelectNotification;
    }

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[LocalNotifications] Timezone init warning: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      final success = await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          _handleNotificationResponse(payload);
        },
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            episodeChannelId,
            episodeChannelName,
            description: episodeChannelDesc,
            importance: Importance.high,
          ),
        );
      }

      // Check if cold-started via a notification click
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _pendingRoute = payload;
        }
      }

      _isInitialized = true;
      return success ?? true;
    } catch (e) {
      debugPrint('[LocalNotifications] Plugin init failed: $e');
      return false;
    }
  }

  void _handleNotificationResponse(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    _pendingRoute = payload;
    onNotificationTapped?.call(payload);
  }

  /// Consumes and clears any pending route resulting from a notification tap.
  String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  /// Requests the POST_NOTIFICATIONS permission on Android 13+ (API 33+).
  Future<bool> requestPermission() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[LocalNotifications] Request permission failed: $e');
      return false;
    }
  }

  /// Checks if notifications are currently enabled for this app.
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Schedules an OS notification for an upcoming episode.
  Future<bool> scheduleEpisodeReminder({
    required EpisodeReminderItem item,
    int leadDays = 0,
    int reminderHour = 9,
    bool quietHoursEnabled = false,
    int quietHoursStart = 22,
    int quietHoursEnd = 8,
  }) async {
    final airDate = item.airDateTime;
    if (airDate == null) return false;

    final scheduled = calculateScheduledDateTime(
      airDate: airDate,
      leadDays: leadDays,
      reminderHour: reminderHour,
      quietHoursEnabled: quietHoursEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
    );

    if (scheduled.isBefore(DateTime.now())) {
      return false;
    }

    try {
      final tzScheduled = tz.TZDateTime.from(scheduled, tz.local);
      final id = generateNotificationId(item.showId);
      final title = '${item.showName} airs ${item.isToday ? "today" : "soon"}!';
      final body = item.episodeName != null && item.episodeName!.isNotEmpty
          ? '${item.episodeName} airs on ${item.airDate}'
          : 'New episode airs on ${item.airDate}';

      const androidDetails = AndroidNotificationDetails(
        episodeChannelId,
        episodeChannelName,
        channelDescription: episodeChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '/tv/${item.showId}',
      );
      return true;
    } catch (e) {
      debugPrint('[LocalNotifications] Scheduling failed: $e');
      return false;
    }
  }

  /// Cancels an existing notification for a given showId.
  Future<void> cancelReminder(int showId) async {
    try {
      await _plugin.cancel(generateNotificationId(showId));
    } catch (_) {}
  }

  /// Cancels all scheduled local notifications.
  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Cancels and synchronizes scheduled notifications for all active upcoming shows.
  Future<void> syncReminders({
    required List<EpisodeReminderItem> items,
    required int leadDays,
    required int reminderHour,
    required bool quietHoursEnabled,
    required int quietHoursStart,
    required int quietHoursEnd,
  }) async {
    await cancelAllReminders();
    for (final item in items) {
      if (item.isEnabled && item.isUpcoming) {
        await scheduleEpisodeReminder(
          item: item,
          leadDays: leadDays,
          reminderHour: reminderHour,
          quietHoursEnabled: quietHoursEnabled,
          quietHoursStart: quietHoursStart,
          quietHoursEnd: quietHoursEnd,
        );
      }
    }
  }

  /// Posts an immediate test notification to verify sound, icon, and channel setup.
  Future<bool> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        episodeChannelId,
        episodeChannelName,
        channelDescription: episodeChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        id: 999999,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('[LocalNotifications] Immediate show failed: $e');
      return false;
    }
  }
}
