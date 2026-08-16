import 'local_time.dart';

final class DailyOverviewReminder {
  const DailyOverviewReminder({
    this.enabled = false,
    this.time = const LocalTime(20, 0),
  });

  factory DailyOverviewReminder.fromMap(Map<String, Object?> map) =>
      DailyOverviewReminder(
        enabled: map['enabled'] as bool? ?? false,
        time: LocalTime.parse(map['time'] as String? ?? '20:00'),
      );

  final bool enabled;
  final LocalTime time;

  Map<String, Object?> toMap() => <String, Object?>{
    'enabled': enabled,
    'time': time.toString(),
  };
}

final class ReminderPreferences {
  ReminderPreferences({
    this.schemaVersion = currentSchemaVersion,
    this.enabled = false,
    this.activeDayStart = const LocalTime(8, 0),
    this.activeDayEnd = const LocalTime(22, 0),
    this.globalDailyLimit = 8,
    this.globalMinimumSpacing = const Duration(minutes: 90),
    Iterable<LocalTimeRange> quietHours = const <LocalTimeRange>[],
    this.calibrationEnabled = true,
    this.ongoingLearningEnabled = true,
    this.showLearningExplanations = true,
    this.defaultSnooze = const Duration(minutes: 30),
    this.dailyOverview = const DailyOverviewReminder(),
    this.existingUserIntroductionSeen = false,
  }) : quietHours = normalizeTimeRanges(quietHours) {
    if (activeDayStart.compareTo(activeDayEnd) >= 0) {
      throw ArgumentError('The active day must start before it ends.');
    }
    if (globalDailyLimit < 1 || globalDailyLimit > 64) {
      throw ArgumentError.value(globalDailyLimit, 'globalDailyLimit');
    }
    if (globalMinimumSpacing <= Duration.zero ||
        defaultSnooze <= Duration.zero) {
      throw ArgumentError('Spacing and snooze durations must be positive.');
    }
  }

  static const currentSchemaVersion = 1;

  factory ReminderPreferences.fromMap(
    Map<String, Object?> map,
  ) => ReminderPreferences(
    schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
    enabled: map['enabled'] as bool? ?? false,
    activeDayStart: LocalTime.parse(
      map['activeDayStart'] as String? ?? '08:00',
    ),
    activeDayEnd: LocalTime.parse(map['activeDayEnd'] as String? ?? '22:00'),
    globalDailyLimit: (map['globalDailyLimit'] as num?)?.toInt() ?? 8,
    globalMinimumSpacing: Duration(
      minutes: (map['globalMinimumSpacingMinutes'] as num?)?.toInt() ?? 90,
    ),
    quietHours: ((map['quietHours'] as List<Object?>?) ?? const <Object?>[])
        .map(
          (value) =>
              LocalTimeRange.fromMap(Map<String, Object?>.from(value! as Map)),
        ),
    calibrationEnabled: map['calibrationEnabled'] as bool? ?? true,
    ongoingLearningEnabled: map['ongoingLearningEnabled'] as bool? ?? true,
    showLearningExplanations: map['showLearningExplanations'] as bool? ?? true,
    defaultSnooze: Duration(
      minutes: (map['defaultSnoozeMinutes'] as num?)?.toInt() ?? 30,
    ),
    dailyOverview: map['dailyOverview'] is Map
        ? DailyOverviewReminder.fromMap(
            Map<String, Object?>.from(map['dailyOverview']! as Map),
          )
        : const DailyOverviewReminder(),
    existingUserIntroductionSeen:
        map['existingUserIntroductionSeen'] as bool? ?? false,
  );

  final int schemaVersion;
  final bool enabled;
  final LocalTime activeDayStart;
  final LocalTime activeDayEnd;
  final int globalDailyLimit;
  final Duration globalMinimumSpacing;
  final List<LocalTimeRange> quietHours;
  final bool calibrationEnabled;
  final bool ongoingLearningEnabled;
  final bool showLearningExplanations;
  final Duration defaultSnooze;
  final DailyOverviewReminder dailyOverview;
  final bool existingUserIntroductionSeen;

  bool allows(LocalTime time) =>
      time.compareTo(activeDayStart) >= 0 &&
      time.compareTo(activeDayEnd) <= 0 &&
      !quietHours.any((range) => range.contains(time));

  ReminderPreferences copyWith({
    bool? enabled,
    LocalTime? activeDayStart,
    LocalTime? activeDayEnd,
    int? globalDailyLimit,
    Duration? globalMinimumSpacing,
    List<LocalTimeRange>? quietHours,
    bool? calibrationEnabled,
    bool? ongoingLearningEnabled,
    bool? showLearningExplanations,
    Duration? defaultSnooze,
    DailyOverviewReminder? dailyOverview,
    bool? existingUserIntroductionSeen,
  }) => ReminderPreferences(
    schemaVersion: schemaVersion,
    enabled: enabled ?? this.enabled,
    activeDayStart: activeDayStart ?? this.activeDayStart,
    activeDayEnd: activeDayEnd ?? this.activeDayEnd,
    globalDailyLimit: globalDailyLimit ?? this.globalDailyLimit,
    globalMinimumSpacing: globalMinimumSpacing ?? this.globalMinimumSpacing,
    quietHours: quietHours ?? this.quietHours,
    calibrationEnabled: calibrationEnabled ?? this.calibrationEnabled,
    ongoingLearningEnabled:
        ongoingLearningEnabled ?? this.ongoingLearningEnabled,
    showLearningExplanations:
        showLearningExplanations ?? this.showLearningExplanations,
    defaultSnooze: defaultSnooze ?? this.defaultSnooze,
    dailyOverview: dailyOverview ?? this.dailyOverview,
    existingUserIntroductionSeen:
        existingUserIntroductionSeen ?? this.existingUserIntroductionSeen,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'enabled': enabled,
    'activeDayStart': activeDayStart.toString(),
    'activeDayEnd': activeDayEnd.toString(),
    'globalDailyLimit': globalDailyLimit,
    'globalMinimumSpacingMinutes': globalMinimumSpacing.inMinutes,
    'quietHours': quietHours.map((range) => range.toMap()).toList(),
    'calibrationEnabled': calibrationEnabled,
    'ongoingLearningEnabled': ongoingLearningEnabled,
    'showLearningExplanations': showLearningExplanations,
    'defaultSnoozeMinutes': defaultSnooze.inMinutes,
    'dailyOverview': dailyOverview.toMap(),
    'existingUserIntroductionSeen': existingUserIntroductionSeen,
  };
}
