import 'dart:async';
import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/persistence/storage_envelope.dart';
import '../../../models/habit.dart';
import '../application/habit_repository.dart';

final class KeyValueHabitRepository implements HabitRepository {
  KeyValueHabitRepository(
    this._store, {
    Set<String> transactionalSidecarKeys = const <String>{},
  }) : _transactionalSidecarKeys = Set<String>.unmodifiable(
         transactionalSidecarKeys,
       );

  static const habitsKey = 'habiter_habits';
  static const entriesKey = 'habiter_habit_entries';
  static const revisionKey = 'habiter_habit_state_revision';

  final KeyValueStore _store;
  final Set<String> _transactionalSidecarKeys;
  Future<void> _queue = Future<void>.value();

  @override
  Future<HabitRepositorySnapshot> load() {
    return _enqueue(_loadUnlocked);
  }

  @override
  Future<void> transact(
    FutureOr<void> Function(HabitRepositoryDraft draft) mutation,
  ) {
    return _enqueue(() async {
      final envelopeValue = await _store.read(StorageEnvelope.storageKey);
      if (envelopeValue != null) {
        await _transactEnvelope(envelopeValue, mutation);
        return;
      }
      final oldHabits = await _store.read(habitsKey);
      final oldEntries = await _store.read(entriesKey);
      final oldRevision = await _store.read(revisionKey);
      final oldSidecar = <String, Object?>{
        for (final key in _transactionalSidecarKeys)
          key: await _store.read(key),
      };
      try {
        final snapshot = _decode(oldHabits, oldEntries, oldRevision);
        final draft = HabitRepositoryDraft(
          habits: snapshot.habits,
          entries: snapshot.entries,
          sidecar: oldSidecar,
        );
        await mutation(draft);
        await _store.write(
          habitsKey,
          jsonEncode(draft.habits.map((habit) => habit.toMap()).toList()),
        );
        await _store.write(
          entriesKey,
          jsonEncode(draft.entries.map((entry) => entry.toMap()).toList()),
        );
        await _store.write(revisionKey, snapshot.revision + 1);
        for (final key in _transactionalSidecarKeys) {
          final value = draft.sidecar[key];
          if (value == null) {
            await _store.remove(key);
          } else {
            await _store.write(key, value);
          }
        }
      } catch (error) {
        await _restore(habitsKey, oldHabits);
        await _restore(entriesKey, oldEntries);
        await _restore(revisionKey, oldRevision);
        for (final entry in oldSidecar.entries) {
          await _restore(entry.key, entry.value);
        }
        if (error is HabitRepositoryException) rethrow;
        throw HabitRepositoryException(
          'The habit transaction failed and was rolled back.',
          cause: error,
        );
      }
    });
  }

  Future<HabitRepositorySnapshot> _loadUnlocked() async {
    try {
      final envelopeValue = await _store.read(StorageEnvelope.storageKey);
      if (envelopeValue != null) {
        if (envelopeValue is! String) {
          throw const HabitRepositoryException(
            'The storage envelope was not JSON text.',
          );
        }
        final envelope = StorageEnvelope.fromJson(envelopeValue);
        return _decode(
          envelope.data[habitsKey],
          envelope.data[entriesKey],
          envelope.data[revisionKey],
        );
      }
      return _decode(
        await _store.read(habitsKey),
        await _store.read(entriesKey),
        await _store.read(revisionKey),
      );
    } catch (error) {
      if (error is HabitRepositoryException) rethrow;
      throw HabitRepositoryException(
        'Stored habit data could not be decoded.',
        cause: error,
      );
    }
  }

  HabitRepositorySnapshot _decode(
    Object? habitsValue,
    Object? entriesValue,
    Object? revisionValue,
  ) {
    return HabitRepositorySnapshot(
      habits: _decodeList(habitsValue, Habit.fromMap),
      entries: _decodeList(entriesValue, HabitEntry.fromMap),
      revision: (revisionValue as num?)?.toInt() ?? 0,
    );
  }

  List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value == null) return <T>[];
    final Object? json = value is String ? jsonDecode(value) : value;
    if (json is! List) {
      throw const HabitRepositoryException(
        'A persisted habit collection was not a JSON list.',
      );
    }
    return json
        .map((item) => decode(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<void> _transactEnvelope(
    Object envelopeValue,
    FutureOr<void> Function(HabitRepositoryDraft draft) mutation,
  ) async {
    try {
      if (envelopeValue is! String) {
        throw const FormatException('Envelope is not JSON text.');
      }
      final envelope = StorageEnvelope.fromJson(envelopeValue);
      final snapshot = _decode(
        envelope.data[habitsKey],
        envelope.data[entriesKey],
        envelope.data[revisionKey],
      );
      final draft = HabitRepositoryDraft(
        habits: snapshot.habits,
        entries: snapshot.entries,
        sidecar: envelope.data,
      );
      await mutation(draft);
      final data = Map<String, Object?>.from(draft.sidecar)
        ..[habitsKey] = _mergeHabits(envelope.data[habitsKey], draft.habits)
        ..[entriesKey] = _mergeEntries(envelope.data[entriesKey], draft.entries)
        ..[revisionKey] = snapshot.revision + 1;
      await _store.write(
        StorageEnvelope.storageKey,
        envelope.withData(data).toJson(),
      );
    } catch (error) {
      if (error is HabitRepositoryException) rethrow;
      throw HabitRepositoryException(
        'The versioned habit transaction failed.',
        cause: error,
      );
    }
  }

  List<Map<String, Object?>> _mergeHabits(
    Object? oldValue,
    List<Habit> habits,
  ) {
    final oldById = _mapsById(oldValue);
    return habits
        .map(
          (habit) => <String, Object?>{...?oldById[habit.id], ...habit.toMap()},
        )
        .toList(growable: false);
  }

  List<Map<String, Object?>> _mergeEntries(
    Object? oldValue,
    List<HabitEntry> entries,
  ) {
    final oldById = _mapsById(oldValue);
    return entries
        .map(
          (entry) => <String, Object?>{...?oldById[entry.id], ...entry.toMap()},
        )
        .toList(growable: false);
  }

  Map<String, Map<String, Object?>> _mapsById(Object? value) {
    if (value is! List) return <String, Map<String, Object?>>{};
    return <String, Map<String, Object?>>{
      for (final item in value)
        if (item is Map && item['id'] is String)
          item['id'] as String: Map<String, Object?>.from(item),
    };
  }

  Future<void> _restore(String key, Object? value) async {
    if (value == null) {
      await _store.remove(key);
    } else {
      await _store.write(key, value);
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _queue = _queue.catchError((Object _) {}).then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
