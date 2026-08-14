import 'dart:async';
import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../models/habit.dart';
import '../application/habit_repository.dart';

final class KeyValueHabitRepository implements HabitRepository {
  KeyValueHabitRepository(this._store);

  static const habitsKey = 'habiter_habits';
  static const entriesKey = 'habiter_habit_entries';

  final KeyValueStore _store;
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
      final oldHabits = await _store.read(habitsKey);
      final oldEntries = await _store.read(entriesKey);
      try {
        final snapshot = _decode(oldHabits, oldEntries);
        final draft = HabitRepositoryDraft(
          habits: snapshot.habits,
          entries: snapshot.entries,
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
      } catch (error) {
        await _restore(habitsKey, oldHabits);
        await _restore(entriesKey, oldEntries);
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
      return _decode(
        await _store.read(habitsKey),
        await _store.read(entriesKey),
      );
    } catch (error) {
      if (error is HabitRepositoryException) rethrow;
      throw HabitRepositoryException(
        'Stored habit data could not be decoded.',
        cause: error,
      );
    }
  }

  HabitRepositorySnapshot _decode(Object? habitsValue, Object? entriesValue) {
    return HabitRepositorySnapshot(
      habits: _decodeList(habitsValue, Habit.fromMap),
      entries: _decodeList(entriesValue, HabitEntry.fromMap),
    );
  }

  List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value == null) return <T>[];
    if (value is! String) {
      throw const HabitRepositoryException(
        'A persisted habit collection was not JSON text.',
      );
    }
    final json = jsonDecode(value);
    if (json is! List) {
      throw const HabitRepositoryException(
        'A persisted habit collection was not a JSON list.',
      );
    }
    return json
        .map((item) => decode(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
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
