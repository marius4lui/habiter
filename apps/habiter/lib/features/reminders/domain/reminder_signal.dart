enum FeasibilityRating {
  good(1),
  maybe(0.5),
  bad(0);

  const FeasibilityRating(this.targetValue);
  final double targetValue;
}

enum SignalSource {
  calibrationNotification,
  fineTuningNotification,
  inAppFeedback,
  habitCompletion,
  notificationCompletion,
  snooze,
}

extension SignalSourceWeights on SignalSource {
  double get baseWeight => switch (this) {
    SignalSource.calibrationNotification ||
    SignalSource.fineTuningNotification ||
    SignalSource.inAppFeedback => 1,
    SignalSource.habitCompletion => 0.35,
    SignalSource.notificationCompletion => 0.8,
    SignalSource.snooze => 0.5,
  };

  bool get isExplicit => switch (this) {
    SignalSource.calibrationNotification ||
    SignalSource.fineTuningNotification ||
    SignalSource.inAppFeedback ||
    SignalSource.snooze => true,
    _ => false,
  };
}

final class ReminderSignal {
  const ReminderSignal({
    required this.id,
    required this.habitId,
    required this.source,
    required this.occurredAtUtc,
    required this.timeZoneId,
    required this.localWeekday,
    required this.localMinuteOfDay,
    this.feasibility,
    this.originatingNotificationKey,
    this.calibrationSessionId,
    this.algorithmVersion = currentAlgorithmVersion,
    required this.createdAt,
  }) : assert(localWeekday >= 1 && localWeekday <= 7),
       assert(localMinuteOfDay >= 0 && localMinuteOfDay < 1440);

  factory ReminderSignal.fromMap(Map<String, Object?> map) => ReminderSignal(
    id: map['id']! as String,
    habitId: map['habitId']! as String,
    source: SignalSource.values.byName(map['source']! as String),
    occurredAtUtc: DateTime.parse(map['occurredAtUtc']! as String).toUtc(),
    timeZoneId: map['timeZoneId']! as String,
    localWeekday: (map['localWeekday']! as num).toInt(),
    localMinuteOfDay: (map['localMinuteOfDay']! as num).toInt(),
    feasibility: map['feasibility'] == null
        ? null
        : FeasibilityRating.values.byName(map['feasibility']! as String),
    originatingNotificationKey: map['originatingNotificationKey'] as String?,
    calibrationSessionId: map['calibrationSessionId'] as String?,
    algorithmVersion: (map['algorithmVersion'] as num?)?.toInt() ?? 1,
    createdAt: DateTime.parse(map['createdAt']! as String),
  );

  static const currentAlgorithmVersion = 1;

  final String id;
  final String habitId;
  final SignalSource source;
  final DateTime occurredAtUtc;
  final String timeZoneId;
  final int localWeekday;
  final int localMinuteOfDay;
  final FeasibilityRating? feasibility;
  final String? originatingNotificationKey;
  final String? calibrationSessionId;
  final int algorithmVersion;
  final DateTime createdAt;

  double get targetValue {
    if (source == SignalSource.snooze) return 0.25;
    if (source.isExplicit) {
      if (feasibility == null) {
        throw StateError('Explicit signals require a feasibility rating.');
      }
      return feasibility!.targetValue;
    }
    return 1;
  }

  double get sourceWeight =>
      source == SignalSource.habitCompletion &&
          originatingNotificationKey != null
      ? 0.65
      : source.baseWeight;

  ReminderSignal withReminderAttribution(String notificationKey) {
    if (source != SignalSource.habitCompletion) return this;
    return ReminderSignal(
      id: id,
      habitId: habitId,
      source: source,
      occurredAtUtc: occurredAtUtc,
      timeZoneId: timeZoneId,
      localWeekday: localWeekday,
      localMinuteOfDay: localMinuteOfDay,
      originatingNotificationKey: notificationKey,
      algorithmVersion: algorithmVersion,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'habitId': habitId,
    'source': source.name,
    'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
    'timeZoneId': timeZoneId,
    'localWeekday': localWeekday,
    'localMinuteOfDay': localMinuteOfDay,
    if (feasibility != null) 'feasibility': feasibility!.name,
    if (originatingNotificationKey != null)
      'originatingNotificationKey': originatingNotificationKey,
    if (calibrationSessionId != null)
      'calibrationSessionId': calibrationSessionId,
    'algorithmVersion': algorithmVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}
