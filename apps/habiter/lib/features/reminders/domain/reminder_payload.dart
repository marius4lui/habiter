import '../../../core/time/local_date.dart';
import 'reminder_plan.dart';

final class ReminderPayload {
  const ReminderPayload({
    required this.habitId,
    required this.occurrence,
    this.notificationKey,
    this.kind = PlannedReminderKind.normal,
    this.reason = const ReminderReason(code: ReminderReasonCode.fixedTime),
    this.snoozeDuration = const Duration(minutes: 30),
    this.action = 'open',
  });

  static const int schemaVersion = 3;
  final String habitId;
  final LocalDate occurrence;
  final String? notificationKey;
  final PlannedReminderKind kind;
  final ReminderReason reason;
  final Duration snoozeDuration;
  final String action;

  String get stableNotificationKey =>
      notificationKey ?? '$habitId@${occurrence.toString()}';

  Map<String, Object?> toMap() => <String, Object?>{
    'v': schemaVersion,
    'habitId': habitId,
    'occurrence': occurrence.toString(),
    'notificationKey': stableNotificationKey,
    'kind': kind.name,
    'reason': reason.toMap(),
    'snoozeDurationMinutes': snoozeDuration.inMinutes,
    'action': action,
  };

  factory ReminderPayload.fromMap(Map<String, Object?> map) {
    final version = (map['v'] as num?)?.toInt();
    if ((version != 1 && version != 2 && version != schemaVersion) ||
        map['habitId'] is! String ||
        map['occurrence'] is! String) {
      throw const FormatException('Unsupported reminder payload.');
    }
    if (version == 1) {
      return ReminderPayload(
        habitId: map['habitId']! as String,
        occurrence: LocalDate.parse(map['occurrence']! as String),
        action: map['action'] as String? ?? 'open',
      );
    }
    return ReminderPayload(
      habitId: map['habitId']! as String,
      occurrence: LocalDate.parse(map['occurrence']! as String),
      notificationKey: map['notificationKey'] as String?,
      kind: PlannedReminderKind.values.byName(
        map['kind'] as String? ?? PlannedReminderKind.normal.name,
      ),
      reason: map['reason'] is Map
          ? ReminderReason.fromMap(
              Map<String, Object?>.from(map['reason']! as Map),
            )
          : const ReminderReason(code: ReminderReasonCode.fixedTime),
      snoozeDuration: Duration(
        minutes: (map['snoozeDurationMinutes'] as num?)?.toInt() ?? 30,
      ),
      action: map['action'] as String? ?? 'open',
    );
  }
}
