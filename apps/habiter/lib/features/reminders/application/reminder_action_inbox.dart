import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../domain/reminder_action.dart';
import '../domain/reminder_signal.dart';

final class ReminderActionRecord {
  const ReminderActionRecord({
    required this.id,
    required this.habitId,
    required this.occurrence,
    required this.receivedAt,
    this.notificationKey,
    this.kind = ReminderActionKind.complete,
    this.snoozeDuration = const Duration(minutes: 30),
  });

  final String id;
  final String habitId;
  final LocalDate occurrence;
  final DateTime receivedAt;
  final String? notificationKey;
  final ReminderActionKind kind;
  final Duration snoozeDuration;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'habitId': habitId,
    'occurrence': occurrence.toString(),
    'receivedAt': receivedAt.toUtc().toIso8601String(),
    if (notificationKey != null) 'notificationKey': notificationKey,
    'kind': kind.name,
    'snoozeDurationMinutes': snoozeDuration.inMinutes,
  };

  factory ReminderActionRecord.fromMap(Map<String, Object?> map) =>
      ReminderActionRecord(
        id: map['id']! as String,
        habitId: map['habitId']! as String,
        occurrence: LocalDate.parse(map['occurrence']! as String),
        receivedAt: DateTime.parse(map['receivedAt']! as String),
        notificationKey: map['notificationKey'] as String?,
        kind: map['kind'] == null
            ? ReminderActionKind.complete
            : ReminderActionKind.values.byName(map['kind']! as String),
        snoozeDuration: Duration(
          minutes: (map['snoozeDurationMinutes'] as num?)?.toInt() ?? 30,
        ),
      );
}

final class ReminderActionInbox {
  ReminderActionInbox(this._store);

  static const storageKey = 'habiter_reminder_action_inbox_v1';
  final KeyValueStore _store;
  Future<void> _tail = Future<void>.value();

  Future<void> enqueue(ReminderActionRecord record) => _serialize(() async {
    final records = await pending();
    if (records.any((item) => item.id == record.id)) return;
    await _write(<ReminderActionRecord>[...records, record]);
  });

  Future<List<ReminderActionRecord>> pending() async {
    final raw = await _store.read(storageKey);
    if (raw == null) return const <ReminderActionRecord>[];
    if (raw is! String) throw const FormatException('Invalid action inbox.');
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Invalid action inbox.');
    }
    return List<ReminderActionRecord>.unmodifiable(
      decoded.map(
        (value) => ReminderActionRecord.fromMap(
          Map<String, Object?>.from(value as Map<dynamic, dynamic>),
        ),
      ),
    );
  }

  Future<void> remove(String id) => _serialize(() async {
    final records = await pending();
    await _write(records.where((record) => record.id != id));
  });

  Future<void> _write(Iterable<ReminderActionRecord> records) => _store.write(
    storageKey,
    jsonEncode(records.map((record) => record.toMap()).toList()),
  );

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.catchError((_) {});
    return result;
  }
}

typedef CompleteReminderOccurrence =
    Future<void> Function(String habitId, String date);
typedef RecordReminderFeasibility =
    Future<void> Function(
      ReminderActionRecord action,
      FeasibilityRating rating,
    );
typedef SnoozeReminder = Future<void> Function(ReminderActionRecord action);
typedef IsReminderActionProcessed = Future<bool> Function(String id);
typedef MarkReminderActionProcessed = Future<void> Function(String id);

final class ReminderActionProcessor {
  const ReminderActionProcessor({
    required ReminderActionInbox inbox,
    required Clock clock,
    required CompleteReminderOccurrence complete,
    RecordReminderFeasibility? recordFeasibility,
    SnoozeReminder? snooze,
    IsReminderActionProcessed? isProcessed,
    MarkReminderActionProcessed? markProcessed,
  }) : _inbox = inbox,
       _clock = clock,
       _complete = complete,
       _recordFeasibility = recordFeasibility,
       _snooze = snooze,
       _isProcessed = isProcessed,
       _markProcessed = markProcessed;

  final ReminderActionInbox _inbox;
  final Clock _clock;
  final CompleteReminderOccurrence _complete;
  final RecordReminderFeasibility? _recordFeasibility;
  final SnoozeReminder? _snooze;
  final IsReminderActionProcessed? _isProcessed;
  final MarkReminderActionProcessed? _markProcessed;

  Future<int> drain() async {
    final today = LocalDate.fromDateTime(_clock.now());
    var processed = 0;
    for (final action in await _inbox.pending()) {
      if (await _isProcessed?.call(action.id) ?? false) {
        await _inbox.remove(action.id);
        continue;
      }
      final feasibility = action.kind.feasibility;
      if (feasibility != null && _recordFeasibility != null) {
        await _recordFeasibility(action, feasibility);
        processed++;
      } else if (action.kind == ReminderActionKind.snooze && _snooze != null) {
        await _snooze(action);
        processed++;
      } else if (action.kind == ReminderActionKind.complete &&
          action.occurrence == today) {
        await _complete(action.habitId, action.occurrence.toString());
        processed++;
      }
      await _markProcessed?.call(action.id);
      await _inbox.remove(action.id);
    }
    return processed;
  }
}
