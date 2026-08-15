import '../../../core/time/local_date.dart';

final class ReminderPayload {
  const ReminderPayload({
    required this.habitId,
    required this.occurrence,
    this.action = 'open',
  });

  static const int schemaVersion = 1;
  final String habitId;
  final LocalDate occurrence;
  final String action;

  Map<String, Object?> toMap() => <String, Object?>{
    'v': schemaVersion,
    'habitId': habitId,
    'occurrence': occurrence.toString(),
    'action': action,
  };

  factory ReminderPayload.fromMap(Map<String, Object?> map) {
    if (map['v'] != schemaVersion || map['habitId'] is! String) {
      throw const FormatException('Unsupported reminder payload.');
    }
    return ReminderPayload(
      habitId: map['habitId']! as String,
      occurrence: LocalDate.parse(map['occurrence']! as String),
      action: map['action'] as String? ?? 'open',
    );
  }
}
