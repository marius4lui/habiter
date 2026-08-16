import '../../../core/time/local_date.dart';

enum CalibrationStatus { notStarted, active, paused, completed, cancelled }

final class CalibrationBucketKey {
  const CalibrationBucketKey({
    required this.localDate,
    required this.twoHourStartMinute,
    required this.habitId,
    required this.timeZoneId,
  }) : assert(twoHourStartMinute >= 0 && twoHourStartMinute < 1440),
       assert(twoHourStartMinute % 120 == 0);

  factory CalibrationBucketKey.fromMap(Map<String, Object?> map) =>
      CalibrationBucketKey(
        localDate: LocalDate.parse(map['localDate']! as String),
        twoHourStartMinute: (map['twoHourStartMinute']! as num).toInt(),
        habitId: map['habitId']! as String,
        timeZoneId: map['timeZoneId']! as String,
      );

  final LocalDate localDate;
  final int twoHourStartMinute;
  final String habitId;
  final String timeZoneId;

  String get storageKey =>
      '${localDate.toString()}|$twoHourStartMinute|$habitId|$timeZoneId';

  Map<String, Object?> toMap() => <String, Object?>{
    'localDate': localDate.toString(),
    'twoHourStartMinute': twoHourStartMinute,
    'habitId': habitId,
    'timeZoneId': timeZoneId,
  };

  @override
  bool operator ==(Object other) =>
      other is CalibrationBucketKey && storageKey == other.storageKey;

  @override
  int get hashCode => storageKey.hashCode;
}

final class CalibrationSession {
  CalibrationSession({
    required this.id,
    this.status = CalibrationStatus.notStarted,
    required this.startedAt,
    required this.plannedEndAt,
    this.completedAt,
    this.answeredPulseCount = 0,
    Iterable<CalibrationBucketKey> coveredBuckets =
        const <CalibrationBucketKey>[],
    this.pausedAt,
  }) : coveredBuckets = Set<CalibrationBucketKey>.unmodifiable(coveredBuckets) {
    if (plannedEndAt.isBefore(startedAt)) {
      throw ArgumentError('Calibration cannot end before it starts.');
    }
  }

  factory CalibrationSession.start({
    required String id,
    required DateTime now,
  }) => CalibrationSession(
    id: id,
    status: CalibrationStatus.active,
    startedAt: now,
    plannedEndAt: now.add(const Duration(days: 7)),
  );

  factory CalibrationSession.fromMap(Map<String, Object?> map) =>
      CalibrationSession(
        id: map['id']! as String,
        status: CalibrationStatus.values.byName(map['status']! as String),
        startedAt: DateTime.parse(map['startedAt']! as String),
        plannedEndAt: DateTime.parse(map['plannedEndAt']! as String),
        completedAt: map['completedAt'] == null
            ? null
            : DateTime.parse(map['completedAt']! as String),
        answeredPulseCount: (map['answeredPulseCount'] as num?)?.toInt() ?? 0,
        coveredBuckets:
            ((map['coveredBuckets'] as List<Object?>?) ?? const <Object?>[])
                .map(
                  (value) => CalibrationBucketKey.fromMap(
                    Map<String, Object?>.from(value! as Map),
                  ),
                ),
        pausedAt: map['pausedAt'] == null
            ? null
            : DateTime.parse(map['pausedAt']! as String),
      );

  final String id;
  final CalibrationStatus status;
  final DateTime startedAt;
  final DateTime plannedEndAt;
  final DateTime? completedAt;
  final int answeredPulseCount;
  final Set<CalibrationBucketKey> coveredBuckets;
  final DateTime? pausedAt;

  int dayNumberAt(DateTime now) =>
      now.difference(startedAt).inDays.clamp(0, 6) + 1;

  CalibrationSession copyWith({
    CalibrationStatus? status,
    DateTime? plannedEndAt,
    DateTime? completedAt,
    int? answeredPulseCount,
    Set<CalibrationBucketKey>? coveredBuckets,
    DateTime? pausedAt,
    bool clearPausedAt = false,
  }) => CalibrationSession(
    id: id,
    status: status ?? this.status,
    startedAt: startedAt,
    plannedEndAt: plannedEndAt ?? this.plannedEndAt,
    completedAt: completedAt ?? this.completedAt,
    answeredPulseCount: answeredPulseCount ?? this.answeredPulseCount,
    coveredBuckets: coveredBuckets ?? this.coveredBuckets,
    pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'status': status.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'plannedEndAt': plannedEndAt.toUtc().toIso8601String(),
    if (completedAt != null)
      'completedAt': completedAt!.toUtc().toIso8601String(),
    'answeredPulseCount': answeredPulseCount,
    'coveredBuckets': coveredBuckets
        .map((bucket) => bucket.toMap())
        .toList(growable: false),
    if (pausedAt != null) 'pausedAt': pausedAt!.toUtc().toIso8601String(),
  };
}
