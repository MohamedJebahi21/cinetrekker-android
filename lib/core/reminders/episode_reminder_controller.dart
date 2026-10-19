import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tv_tracking/presentation/tv_tracking_controller.dart';
import '../models/media_models.dart';
import '../notifications/local_notification_service.dart';
import 'episode_reminder_models.dart';
export 'episode_reminder_models.dart';
import 'episode_reminder_service.dart';

final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService.instance;
});

final episodeReminderServiceProvider = Provider<EpisodeReminderService>((ref) {
  final notificationService = ref.watch(localNotificationServiceProvider);
  return EpisodeReminderService(notificationService: notificationService);
});

class EpisodeReminderState {
  const EpisodeReminderState({
    this.preferences = const EpisodeReminderPreference(),
    this.reminders = const <EpisodeReminderItem>[],
    this.isLoading = false,
  });

  final EpisodeReminderPreference preferences;
  final List<EpisodeReminderItem> reminders;
  final bool isLoading;

  List<EpisodeReminderItem> get activeReminders =>
      reminders.where((r) => r.isEnabled && r.isUpcoming).toList(growable: false);

  int get activeCount => activeReminders.length;

  bool isShowReminded(int showId) =>
      preferences.isShowEnabled(showId) &&
      reminders.any((r) => r.showId == showId && r.isEnabled && r.isUpcoming);

  EpisodeReminderState copyWith({
    EpisodeReminderPreference? preferences,
    List<EpisodeReminderItem>? reminders,
    bool? isLoading,
  }) {
    return EpisodeReminderState(
      preferences: preferences ?? this.preferences,
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EpisodeReminderController extends StateNotifier<EpisodeReminderState> {
  EpisodeReminderController(this._service, this._followedShows)
      : super(const EpisodeReminderState()) {
    _init();
  }

  final EpisodeReminderService _service;
  List<FollowedShowItem> _followedShows;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final prefs = await _service.loadPreferences();
    final reminders = _service.computeReminders(
      followedShows: _followedShows,
      preferences: prefs,
    );
    state = state.copyWith(
      preferences: prefs,
      reminders: reminders,
      isLoading: false,
    );
    await _service.syncScheduledNotifications(
      reminders: reminders,
      preferences: prefs,
    );
  }

  void updateFollowedShows(List<FollowedShowItem> shows) {
    _followedShows = shows;
    final reminders = _service.computeReminders(
      followedShows: _followedShows,
      preferences: state.preferences,
    );
    state = state.copyWith(reminders: reminders);
    _service.syncScheduledNotifications(
      reminders: reminders,
      preferences: state.preferences,
    );
  }

  Future<void> toggleGlobal(bool enabled) async {
    final updated = state.preferences.copyWith(enabled: enabled);
    await _service.savePreferences(updated);
    final reminders = _service.computeReminders(
      followedShows: _followedShows,
      preferences: updated,
    );
    state = state.copyWith(preferences: updated, reminders: reminders);
    await _service.syncScheduledNotifications(
      reminders: reminders,
      preferences: updated,
    );
  }

  Future<void> setLeadDays(int leadDays) async {
    final updated = state.preferences.copyWith(leadDays: leadDays);
    await _service.savePreferences(updated);
    state = state.copyWith(preferences: updated);
    await _service.syncScheduledNotifications(
      reminders: state.reminders,
      preferences: updated,
    );
  }

  Future<void> setReminderHour(int reminderHour) async {
    final updated = state.preferences.copyWith(reminderHour: reminderHour);
    await _service.savePreferences(updated);
    state = state.copyWith(preferences: updated);
    await _service.syncScheduledNotifications(
      reminders: state.reminders,
      preferences: updated,
    );
  }

  Future<void> toggleQuietHours(bool enabled) async {
    final updated = state.preferences.copyWith(quietHoursEnabled: enabled);
    await _service.savePreferences(updated);
    state = state.copyWith(preferences: updated);
    await _service.syncScheduledNotifications(
      reminders: state.reminders,
      preferences: updated,
    );
  }

  Future<void> setQuietHours(int start, int end) async {
    final updated = state.preferences.copyWith(
      quietHoursStart: start,
      quietHoursEnd: end,
    );
    await _service.savePreferences(updated);
    state = state.copyWith(preferences: updated);
    await _service.syncScheduledNotifications(
      reminders: state.reminders,
      preferences: updated,
    );
  }

  Future<void> toggleShowReminder(int showId) async {
    final currentMap = Map<int, bool>.from(state.preferences.showReminders);
    final currentlyEnabled = currentMap[showId] ?? true;
    currentMap[showId] = !currentlyEnabled;

    final updated = state.preferences.copyWith(showReminders: currentMap);
    await _service.savePreferences(updated);
    final reminders = _service.computeReminders(
      followedShows: _followedShows,
      preferences: updated,
    );
    state = state.copyWith(preferences: updated, reminders: reminders);

    final showItem = reminders.cast<EpisodeReminderItem?>().firstWhere(
          (r) => r?.showId == showId,
          orElse: () => null,
        );
    if (showItem != null) {
      await _service.scheduleOrCancelShowNotification(
        item: showItem,
        preferences: updated,
      );
    } else {
      await _service.notificationService.cancelReminder(showId);
    }
  }

  Future<bool> addToCalendar(EpisodeReminderItem item) async {
    return await _service.launchCalendarEvent(
      item,
      reminderHour: state.preferences.reminderHour,
    );
  }

  Future<bool> requestNotificationPermissions() async {
    return await _service.notificationService.requestPermission();
  }

  Future<bool> areNotificationsEnabled() async {
    return await _service.notificationService.areNotificationsEnabled();
  }

  Future<bool> sendTestNotification() async {
    return await _service.notificationService.showImmediateNotification(
      title: 'CineTrekker Notifications Active',
      body:
          'You will receive alerts when new episodes of your tracked TV series air.',
      payload: '/tv-tracking',
    );
  }
}

final episodeReminderControllerProvider =
    StateNotifierProvider<EpisodeReminderController, EpisodeReminderState>((ref) {
  final service = ref.watch(episodeReminderServiceProvider);
  final tvState = ref.watch(tvTrackingControllerProvider);
  final controller = EpisodeReminderController(service, tvState.followedShows);

  // Keep followed shows in sync
  ref.listen<TvTrackingState>(tvTrackingControllerProvider, (_, next) {
    controller.updateFollowedShows(next.followedShows);
  });

  return controller;
});
