import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tv_tracking/presentation/tv_tracking_controller.dart';
import '../models/media_models.dart';
import 'episode_reminder_models.dart';
export 'episode_reminder_models.dart';
import 'episode_reminder_service.dart';

final episodeReminderServiceProvider = Provider<EpisodeReminderService>((ref) {
  return EpisodeReminderService();
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
  }

  void updateFollowedShows(List<FollowedShowItem> shows) {
    _followedShows = shows;
    final reminders = _service.computeReminders(
      followedShows: _followedShows,
      preferences: state.preferences,
    );
    state = state.copyWith(reminders: reminders);
  }

  Future<void> toggleGlobal(bool enabled) async {
    final updated = state.preferences.copyWith(enabled: enabled);
    await _service.savePreferences(updated);
    final reminders = _service.computeReminders(
      followedShows: _followedShows,
      preferences: updated,
    );
    state = state.copyWith(preferences: updated, reminders: reminders);
  }

  Future<void> setLeadDays(int leadDays) async {
    final updated = state.preferences.copyWith(leadDays: leadDays);
    await _service.savePreferences(updated);
    state = state.copyWith(preferences: updated);
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
  }

  Future<bool> addToCalendar(EpisodeReminderItem item) async {
    return await _service.launchCalendarEvent(
      item,
      reminderHour: state.preferences.reminderHour,
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
