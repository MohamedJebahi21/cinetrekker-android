class EpisodeReminderPreference {
  const EpisodeReminderPreference({
    this.enabled = true,
    this.leadDays = 0,
    this.reminderHour = 9,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.showReminders = const <int, bool>{},
  });

  /// Master switch for episode release reminders
  final bool enabled;

  /// Days before release date to remind:
  /// 0 = on air date, 1 = 1 day before, 2 = 2 days before
  final int leadDays;

  /// Preferred hour of the day (0-23, default 9:00 AM)
  final int reminderHour;

  /// Whether quiet hours should suppress active alerts
  final bool quietHoursEnabled;

  /// Quiet hours start (hour 0-23, e.g. 22 for 10 PM)
  final int quietHoursStart;

  /// Quiet hours end (hour 0-23, e.g. 8 for 8 AM)
  final int quietHoursEnd;

  /// Map of showId to custom reminder override (true = enabled, false = muted)
  final Map<int, bool> showReminders;

  bool isShowEnabled(int showId) =>
      enabled && (showReminders[showId] ?? true);

  String get leadDaysLabel {
    switch (leadDays) {
      case 0:
        return 'On release day';
      case 1:
        return '1 day before';
      case 2:
        return '2 days before';
      default:
        return '$leadDays days before';
    }
  }

  EpisodeReminderPreference copyWith({
    bool? enabled,
    int? leadDays,
    int? reminderHour,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    Map<int, bool>? showReminders,
  }) {
    return EpisodeReminderPreference(
      enabled: enabled ?? this.enabled,
      leadDays: leadDays ?? this.leadDays,
      reminderHour: reminderHour ?? this.reminderHour,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      showReminders: showReminders ?? this.showReminders,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': enabled,
    'leadDays': leadDays,
    'reminderHour': reminderHour,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
    'showReminders': showReminders.map(
      (k, v) => MapEntry<String, dynamic>(k.toString(), v),
    ),
  };

  factory EpisodeReminderPreference.fromJson(Map<String, dynamic> json) {
    final rawShows = json['showReminders'];
    final shows = <int, bool>{};
    if (rawShows is Map) {
      for (final entry in rawShows.entries) {
        final key = int.tryParse(entry.key.toString());
        if (key != null && entry.value is bool) {
          shows[key] = entry.value as bool;
        }
      }
    }
    return EpisodeReminderPreference(
      enabled: json['enabled'] as bool? ?? true,
      leadDays: (json['leadDays'] as num?)?.toInt() ?? 0,
      reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 9,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: (json['quietHoursStart'] as num?)?.toInt() ?? 22,
      quietHoursEnd: (json['quietHoursEnd'] as num?)?.toInt() ?? 8,
      showReminders: shows,
    );
  }
}

class EpisodeReminderItem {
  const EpisodeReminderItem({
    required this.showId,
    required this.showName,
    required this.airDate,
    this.episodeName,
    this.posterPath,
    this.isEnabled = true,
  });

  final int showId;
  final String showName;
  final String airDate;
  final String? episodeName;
  final String? posterPath;
  final bool isEnabled;

  DateTime? get airDateTime => DateTime.tryParse(airDate);

  int? get daysUntilAir {
    final dt = airDateTime;
    if (dt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    return target.difference(today).inDays;
  }

  bool get isToday => daysUntilAir == 0;
  bool get isTomorrow => daysUntilAir == 1;
  bool get isUpcoming => (daysUntilAir ?? -1) >= 0;

  String get relativeDateLabel {
    final d = daysUntilAir;
    if (d == null) return airDate;
    if (d < 0) return '${-d}d ago';
    if (d == 0) return 'Today';
    if (d == 1) return 'Tomorrow';
    return 'In $d days';
  }

  /// Builds a universal Google Calendar / Android Calendar intent URL
  Uri buildCalendarUri({int reminderHour = 9}) {
    final dt = airDateTime ?? DateTime.now();
    final start = DateTime(dt.year, dt.month, dt.day, reminderHour, 0);
    final end = start.add(const Duration(hours: 1));

    String formatUtc(DateTime d) {
      final u = d.toUtc();
      return '${u.year.toString().padLeft(4, '0')}'
          '${u.month.toString().padLeft(2, '0')}'
          '${u.day.toString().padLeft(2, '0')}T'
          '${u.hour.toString().padLeft(2, '0')}'
          '${u.minute.toString().padLeft(2, '0')}'
          '${u.second.toString().padLeft(2, '0')}Z';
    }

    final epLabel = episodeName != null && episodeName!.isNotEmpty
        ? ' • $episodeName'
        : '';
    final title = 'CineTrekker: $showName$epLabel';
    final details =
        'New episode of $showName is airing today!\n'
        'Air date: $airDate\n'
        'Tracked in CineTrekker Android.';

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${formatUtc(start)}/${formatUtc(end)}',
      'details': details,
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'showId': showId,
    'showName': showName,
    'airDate': airDate,
    'episodeName': episodeName,
    'posterPath': posterPath,
    'isEnabled': isEnabled,
  };

  factory EpisodeReminderItem.fromJson(Map<String, dynamic> json) =>
      EpisodeReminderItem(
        showId: (json['showId'] as num?)?.toInt() ?? 0,
        showName: json['showName'] as String? ?? 'Show',
        airDate: json['airDate'] as String? ?? '',
        episodeName: json['episodeName'] as String?,
        posterPath: json['posterPath'] as String?,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );
}
