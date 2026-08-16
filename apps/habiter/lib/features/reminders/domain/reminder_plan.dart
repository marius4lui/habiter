import 'local_time.dart';

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
