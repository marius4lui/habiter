import 'dart:collection';

import 'local_time.dart';

enum ReminderMode { smart, randomWithinWindow, fixedTimes }

enum ReminderIntensity {
  gentle(1),
  balanced(2),
  persistent(3);

  const ReminderIntensity(this.maximumAttempts);
  final int maximumAttempts;
}

enum PeakWindowSource { learned, userDefined }

final class SmartReminderConfig {
  SmartReminderConfig({
    this.windowSource = PeakWindowSource.learned,
    Iterable<LocalTimeRange> userPeakWindows = const <LocalTimeRange>[],
    this.minimumAttemptSpacing = const Duration(hours: 2),
    this.allowFineTuningQuestions = true,
  }) : userPeakWindows = normalizeTimeRanges(userPeakWindows) {
    if (windowSource == PeakWindowSource.userDefined &&
        this.userPeakWindows.isEmpty) {
      throw ArgumentError('User-defined Smart windows must not be empty.');
    }
    if (minimumAttemptSpacing < const Duration(hours: 2)) {
      throw ArgumentError.value(
        minimumAttemptSpacing,
        'minimumAttemptSpacing',
        'Smart attempts require at least two hours of spacing.',
      );
    }
  }

  factory SmartReminderConfig.fromMap(
    Map<String, Object?> map,
  ) => SmartReminderConfig(
    windowSource: PeakWindowSource.values.byName(
      map['windowSource'] as String? ?? PeakWindowSource.learned.name,
    ),
    userPeakWindows:
        ((map['userPeakWindows'] as List<Object?>?) ?? const <Object?>[]).map(
          (value) =>
              LocalTimeRange.fromMap(Map<String, Object?>.from(value! as Map)),
        ),
    minimumAttemptSpacing: Duration(
      minutes: (map['minimumAttemptSpacingMinutes'] as num?)?.toInt() ?? 120,
    ),
    allowFineTuningQuestions: map['allowFineTuningQuestions'] as bool? ?? true,
  );

  final PeakWindowSource windowSource;
  final List<LocalTimeRange> userPeakWindows;
  final Duration minimumAttemptSpacing;
  final bool allowFineTuningQuestions;

  Map<String, Object?> toMap() => <String, Object?>{
    'windowSource': windowSource.name,
    'userPeakWindows': userPeakWindows
        .map((range) => range.toMap())
        .toList(growable: false),
    'minimumAttemptSpacingMinutes': minimumAttemptSpacing.inMinutes,
    'allowFineTuningQuestions': allowFineTuningQuestions,
  };
}

final class RandomReminderConfig {
  RandomReminderConfig({
    required this.window,
    this.timesPerHabitDay = 1,
    this.minimumSpacing = const Duration(hours: 2),
  }) {
    if (window.durationMinutes == 0) {
      throw ArgumentError.value(window, 'window', 'Window must not be empty.');
    }
    if (timesPerHabitDay < 1 || timesPerHabitDay > 4) {
      throw ArgumentError.value(
        timesPerHabitDay,
        'timesPerHabitDay',
        'Must be between 1 and 4.',
      );
    }
    if (minimumSpacing <= Duration.zero) {
      throw ArgumentError.value(
        minimumSpacing,
        'minimumSpacing',
        'Must be positive.',
      );
    }
  }

  factory RandomReminderConfig.fromMap(Map<String, Object?> map) =>
      RandomReminderConfig(
        window: LocalTimeRange.fromMap(
          Map<String, Object?>.from(map['window']! as Map),
        ),
        timesPerHabitDay: (map['timesPerHabitDay'] as num?)?.toInt() ?? 1,
        minimumSpacing: Duration(
          minutes: (map['minimumSpacingMinutes'] as num?)?.toInt() ?? 120,
        ),
      );

  final LocalTimeRange window;
  final int timesPerHabitDay;
  final Duration minimumSpacing;

  Map<String, Object?> toMap() => <String, Object?>{
    'window': window.toMap(),
    'timesPerHabitDay': timesPerHabitDay,
    'minimumSpacingMinutes': minimumSpacing.inMinutes,
  };
}

final class FixedReminderConfig {
  FixedReminderConfig(Iterable<LocalTime> times)
    : times = List<LocalTime>.unmodifiable((times.toSet().toList()..sort())) {
    if (this.times.isEmpty || this.times.length > 6) {
      throw ArgumentError.value(times, 'times', 'Must contain 1 to 6 times.');
    }
  }

  factory FixedReminderConfig.fromMap(Map<String, Object?> map) =>
      FixedReminderConfig(
        ((map['times'] as List<Object?>?) ?? const <Object?>[]).map(
          (value) => LocalTime.parse(value! as String),
        ),
      );

  final List<LocalTime> times;

  Map<String, Object?> toMap() => <String, Object?>{
    'times': times.map((time) => time.toString()).toList(growable: false),
  };
}

final class HabitReminderPolicy {
  HabitReminderPolicy({
    this.schemaVersion = currentSchemaVersion,
    required this.habitId,
    required this.enabled,
    required this.mode,
    this.intensity = ReminderIntensity.persistent,
    this.smart,
    this.random,
    this.fixed,
    this.snoozeDuration = const Duration(minutes: 30),
    required this.createdAt,
    required this.updatedAt,
    Map<String, Object?> additionalFields = const <String, Object?>{},
  }) : additionalFields = UnmodifiableMapView<String, Object?>(
         Map<String, Object?>.from(additionalFields),
       ) {
    if (schemaVersion < 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    if (habitId.isEmpty) throw ArgumentError.value(habitId, 'habitId');
    if (snoozeDuration <= Duration.zero) {
      throw ArgumentError.value(snoozeDuration, 'snoozeDuration');
    }
    final validConfig = switch (mode) {
      ReminderMode.smart => smart != null && random == null && fixed == null,
      ReminderMode.randomWithinWindow =>
        random != null && smart == null && fixed == null,
      ReminderMode.fixedTimes =>
        fixed != null && smart == null && random == null,
    };
    if (!validConfig) {
      throw ArgumentError('Exactly the configuration for $mode is required.');
    }
  }

  static const currentSchemaVersion = 1;

  factory HabitReminderPolicy.smart({
    required String habitId,
    required DateTime now,
    bool enabled = true,
    ReminderIntensity intensity = ReminderIntensity.persistent,
    SmartReminderConfig? config,
  }) => HabitReminderPolicy(
    habitId: habitId,
    enabled: enabled,
    mode: ReminderMode.smart,
    intensity: intensity,
    smart: config ?? SmartReminderConfig(),
    createdAt: now,
    updatedAt: now,
  );

  factory HabitReminderPolicy.fixedTimes({
    required String habitId,
    required Iterable<LocalTime> times,
    required DateTime now,
    bool enabled = true,
    ReminderIntensity intensity = ReminderIntensity.gentle,
  }) => HabitReminderPolicy(
    habitId: habitId,
    enabled: enabled,
    mode: ReminderMode.fixedTimes,
    intensity: intensity,
    fixed: FixedReminderConfig(times),
    createdAt: now,
    updatedAt: now,
  );

  factory HabitReminderPolicy.fromMap(Map<String, Object?> map) {
    const known = <String>{
      'schemaVersion',
      'habitId',
      'enabled',
      'mode',
      'intensity',
      'smart',
      'random',
      'fixed',
      'snoozeDurationMinutes',
      'createdAt',
      'updatedAt',
    };
    return HabitReminderPolicy(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      habitId: map['habitId']! as String,
      enabled: map['enabled'] as bool? ?? false,
      mode: ReminderMode.values.byName(map['mode']! as String),
      intensity: ReminderIntensity.values.byName(
        map['intensity'] as String? ?? ReminderIntensity.gentle.name,
      ),
      smart: map['smart'] is Map
          ? SmartReminderConfig.fromMap(
              Map<String, Object?>.from(map['smart']! as Map),
            )
          : null,
      random: map['random'] is Map
          ? RandomReminderConfig.fromMap(
              Map<String, Object?>.from(map['random']! as Map),
            )
          : null,
      fixed: map['fixed'] is Map
          ? FixedReminderConfig.fromMap(
              Map<String, Object?>.from(map['fixed']! as Map),
            )
          : null,
      snoozeDuration: Duration(
        minutes: (map['snoozeDurationMinutes'] as num?)?.toInt() ?? 30,
      ),
      createdAt: DateTime.parse(map['createdAt']! as String),
      updatedAt: DateTime.parse(map['updatedAt']! as String),
      additionalFields: Map<String, Object?>.from(map)
        ..removeWhere((key, _) => known.contains(key)),
    );
  }

  final int schemaVersion;
  final String habitId;
  final bool enabled;
  final ReminderMode mode;
  final ReminderIntensity intensity;
  final SmartReminderConfig? smart;
  final RandomReminderConfig? random;
  final FixedReminderConfig? fixed;
  final Duration snoozeDuration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, Object?> additionalFields;

  HabitReminderPolicy copyWith({
    bool? enabled,
    ReminderMode? mode,
    ReminderIntensity? intensity,
    SmartReminderConfig? smart,
    RandomReminderConfig? random,
    FixedReminderConfig? fixed,
    Duration? snoozeDuration,
    DateTime? updatedAt,
  }) {
    final nextMode = mode ?? this.mode;
    return HabitReminderPolicy(
      schemaVersion: schemaVersion,
      habitId: habitId,
      enabled: enabled ?? this.enabled,
      mode: nextMode,
      intensity: intensity ?? this.intensity,
      smart: nextMode == ReminderMode.smart ? (smart ?? this.smart) : null,
      random: nextMode == ReminderMode.randomWithinWindow
          ? (random ?? this.random)
          : null,
      fixed: nextMode == ReminderMode.fixedTimes ? (fixed ?? this.fixed) : null,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalFields: additionalFields,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    ...additionalFields,
    'schemaVersion': schemaVersion,
    'habitId': habitId,
    'enabled': enabled,
    'mode': mode.name,
    'intensity': intensity.name,
    if (smart != null) 'smart': smart!.toMap(),
    if (random != null) 'random': random!.toMap(),
    if (fixed != null) 'fixed': fixed!.toMap(),
    'snoozeDurationMinutes': snoozeDuration.inMinutes,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}
