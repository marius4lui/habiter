import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';

final class ReminderActionRecord {
  const ReminderActionRecord({
    required this.id,
    required this.habitId,
    required this.occurrence,
    required this.receivedAt,
  });

  final String id;
  final String habitId;
  final LocalDate occurrence;
  final DateTime receivedAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'habitId': habitId,
    'occurrence': occurrence.toString(),
    'receivedAt': receivedAt.toUtc().toIso8601String(),
  };

  factory ReminderActionRecord.fromMap(Map<String, Object?> map) =>
      ReminderActionRecord(
        id: map['id']! as String,
        habitId: map['habitId']! as String,
        occurrence: LocalDate.parse(map['occurrence']! as String),
        receivedAt: DateTime.parse(map['receivedAt']! as String),
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

final class ReminderActionProcessor {
  const ReminderActionProcessor({
    required ReminderActionInbox inbox,
    required Clock clock,
    required CompleteReminderOccurrence complete,
  }) : _inbox = inbox,
       _clock = clock,
       _complete = complete;

  final ReminderActionInbox _inbox;
  final Clock _clock;
  final CompleteReminderOccurrence _complete;

  Future<int> drain() async {
    final today = LocalDate.fromDateTime(_clock.now());
    var processed = 0;
    for (final action in await _inbox.pending()) {
      if (action.occurrence == today) {
        await _complete(action.habitId, action.occurrence.toString());
        processed++;
      }
      await _inbox.remove(action.id);
    }
    return processed;
  }
}
