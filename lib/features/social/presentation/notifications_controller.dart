import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_messages.dart';
import '../data/social_repository.dart';

class NotificationsState {
  const NotificationsState({
    required this.notifications,
    required this.isLoading,
    required this.error,
  });

  factory NotificationsState.initial() {
    return const NotificationsState(
      notifications: <SocialNotification>[],
      isLoading: false,
      error: null,
    );
  }

  final List<SocialNotification> notifications;
  final bool isLoading;
  final String? error;

  NotificationsState copyWith({
    List<SocialNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    return NotificationsState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(socialRepositoryProvider);
      final notifications = await repository.getNotifications();
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> markAllRead() async {
    final repository = ref.read(socialRepositoryProvider);
    await repository.markAllNotificationsRead();
    await load();
  }

  void markAsRead(String notificationId) {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return SocialNotification(
          id: n.id,
          type: n.type,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }
}
