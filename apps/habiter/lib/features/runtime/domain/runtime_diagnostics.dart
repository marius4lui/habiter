import 'runtime_feature_state.dart';

final class RuntimeDiagnostics {
  const RuntimeDiagnostics({
    required this.features,
    this.runtimeStartedAt,
    this.lastHeartbeatAt,
    this.lastReminderEvaluationAt,
    this.nextReminderEvaluationAt,
    this.lastNotificationDispatchAt,
    this.lastStartReason,
  });

  factory RuntimeDiagnostics.fromMap(Map<String, Object?> map) =>
      RuntimeDiagnostics(
        features: RuntimeFeatureState.fromMap(map),
        runtimeStartedAt: _dateTime(map['runtimeStartedAt']),
        lastHeartbeatAt: _dateTime(map['lastHeartbeatAt']),
        lastReminderEvaluationAt: _dateTime(map['lastReminderEvaluationAt']),
        nextReminderEvaluationAt: _dateTime(map['nextReminderEvaluationAt']),
        lastNotificationDispatchAt: _dateTime(
          map['lastNotificationDispatchAt'],
        ),
        lastStartReason: map['lastStartReason'] as String?,
      );

  final RuntimeFeatureState features;
  final DateTime? runtimeStartedAt;
  final DateTime? lastHeartbeatAt;
  final DateTime? lastReminderEvaluationAt;
  final DateTime? nextReminderEvaluationAt;
  final DateTime? lastNotificationDispatchAt;
  final String? lastStartReason;
}

DateTime? _dateTime(Object? milliseconds) {
  if (milliseconds is! num || milliseconds.toInt() <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt(), isUtc: true);
}
