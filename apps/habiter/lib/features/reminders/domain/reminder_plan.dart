import 'local_time.dart';
import '../../../core/time/local_date.dart';

enum PlannedReminderKind {
  normal,
  calibrationPulse,
  fineTuningQuestion,
  snooze,
  dailyOverview,
}

enum ReminderReasonCode {
  habitLearnedPeak,
  globalLearnedPeak,
  categoryPreset,
  userDefinedWindow,
  generalDefault,
  deterministicRandom,
  fixedTime,
  calibrationUncertainty,
  fineTuningUncertainty,
  snoozedByUser,
  dailyOverview,
}

final class ReminderReason {
  const ReminderReason({
    required this.code,
    this.sourceProfileId,
    this.window,
    this.positiveExplicitSignals = 0,
    this.negativeExplicitSignals = 0,
    this.factors = const <String, double>{},
  });

  factory ReminderReason.fromMap(Map<String, Object?> map) => ReminderReason(
    code: ReminderReasonCode.values.byName(map['code']! as String),
    sourceProfileId: map['sourceProfileId'] as String?,
    window: map['window'] is Map
        ? LocalTimeRange.fromMap(
            Map<String, Object?>.from(map['window']! as Map),
          )
        : null,
    positiveExplicitSignals:
        (map['positiveExplicitSignals'] as num?)?.toInt() ?? 0,
    negativeExplicitSignals:
        (map['negativeExplicitSignals'] as num?)?.toInt() ?? 0,
    factors: ((map['factors'] as Map<Object?, Object?>?) ?? const {}).map(
      (key, value) => MapEntry(key as String, (value as num).toDouble()),
    ),
  );

  final ReminderReasonCode code;
  final String? sourceProfileId;
  final LocalTimeRange? window;
  final int positiveExplicitSignals;
  final int negativeExplicitSignals;
  final Map<String, double> factors;

  ReminderReason copyWith({ReminderReasonCode? code}) => ReminderReason(
    code: code ?? this.code,
    sourceProfileId: sourceProfileId,
    window: window,
    positiveExplicitSignals: positiveExplicitSignals,
    negativeExplicitSignals: negativeExplicitSignals,
    factors: factors,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'code': code.name,
    if (sourceProfileId != null) 'sourceProfileId': sourceProfileId,
    if (window != null) 'window': window!.toMap(),
    'positiveExplicitSignals': positiveExplicitSignals,
    'negativeExplicitSignals': negativeExplicitSignals,
    'factors': factors,
  };
}

final class PersistedPlannedReminder {
  const PersistedPlannedReminder({
    required this.logicalKey,
    required this.habitId,
    required this.occurrence,
    required this.scheduledFor,
    required this.kind,
    required this.reason,
  });

  factory PersistedPlannedReminder.fromMap(Map<String, Object?> map) =>
      PersistedPlannedReminder(
        logicalKey: map['logicalKey']! as String,
        habitId: map['habitId']! as String,
        occurrence: LocalDate.parse(map['occurrence']! as String),
        scheduledFor: DateTime.parse(map['scheduledFor']! as String),
        kind: PlannedReminderKind.values.byName(map['kind']! as String),
        reason: ReminderReason.fromMap(
          Map<String, Object?>.from(map['reason']! as Map),
        ),
      );

  final String logicalKey;
  final String habitId;
  final LocalDate occurrence;
  final DateTime scheduledFor;
  final PlannedReminderKind kind;
  final ReminderReason reason;

  Map<String, Object?> toMap() => <String, Object?>{
    'logicalKey': logicalKey,
    'habitId': habitId,
    'occurrence': occurrence.toString(),
    'scheduledFor': scheduledFor.toUtc().toIso8601String(),
    'kind': kind.name,
    'reason': reason.toMap(),
  };
}

final class PendingReminderSnooze {
  const PendingReminderSnooze({
    required this.id,
    required this.habitId,
    required this.occurrence,
    required this.scheduledFor,
    required this.createdAt,
  });

  factory PendingReminderSnooze.fromMap(Map<String, Object?> map) =>
      PendingReminderSnooze(
        id: map['id']! as String,
        habitId: map['habitId']! as String,
        occurrence: LocalDate.parse(map['occurrence']! as String),
        scheduledFor: DateTime.parse(map['scheduledFor']! as String),
        createdAt: DateTime.parse(map['createdAt']! as String),
      );

  final String id;
  final String habitId;
  final LocalDate occurrence;
  final DateTime scheduledFor;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'habitId': habitId,
    'occurrence': occurrence.toString(),
    'scheduledFor': scheduledFor.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}
