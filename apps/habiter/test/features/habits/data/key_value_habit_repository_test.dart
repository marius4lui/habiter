import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/persistence/key_value_store.dart';
import 'package:habiter/features/habits/application/habit_repository.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/models/habit.dart';

import '../../../support/fakes/in_memory_key_value_store.dart';

void main() {
  Habit habit(String id) => Habit(
    id: id,
    name: 'Habit $id',
    color: '#123456',
    icon: 'check',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    category: 'General',
    createdAt: DateTime.utc(2026, 1, 1),
    isActive: true,
  );

  HabitEntry entry(String id, String habitId, String date) => HabitEntry(
    id: id,
    habitId: habitId,
    date: date,
    completed: true,
    count: 1,
    timestamp: DateTime.utc(2026, 1, 1),
  );

  group('KeyValueHabitRepository', () {
    test(
      'loads the exact legacy keys through the repository boundary',
      () async {
        final store = InMemoryKeyValueStore(<String, Object?>{
          KeyValueHabitRepository.habitsKey: jsonEncode(<Map<String, Object?>>[
            habit('one').toMap(),
          ]),
          KeyValueHabitRepository.entriesKey: jsonEncode(<Map<String, Object?>>[
            entry('entry-1', 'one', '2026-01-01').toMap(),
          ]),
        });
        final repository = KeyValueHabitRepository(store);

        final snapshot = await repository.load();

        expect(snapshot.habits.map((value) => value.id), <String>['one']);
        expect(snapshot.entries.map((value) => value.id), <String>['entry-1']);
      },
    );

    test('commits habit and entry changes as one transaction', () async {
      final store = InMemoryKeyValueStore();
      final repository = KeyValueHabitRepository(store);

      await repository.transact((draft) {
        draft.upsertHabit(habit('one'));
        draft.upsertEntry(entry('entry-1', 'one', '2026-01-01'));
      });

      final snapshot = await repository.load();
      expect(snapshot.habits.single.id, 'one');
      expect(snapshot.entries.single.id, 'entry-1');
      expect(snapshot.revision, 1);
      expect(store.writes.map((write) => write.key), <String>[
        KeyValueHabitRepository.habitsKey,
        KeyValueHabitRepository.entriesKey,
        KeyValueHabitRepository.revisionKey,
      ]);
    });

    test('delete cascades entries and new habits stay at the top', () async {
      final store = InMemoryKeyValueStore();
      final repository = KeyValueHabitRepository(store);
      await repository.transact((draft) {
        draft.upsertHabit(habit('one'));
        draft.upsertHabit(habit('two'));
        draft.upsertEntry(entry('entry-1', 'one', '2026-01-01'));
      });

      await repository.transact((draft) => draft.deleteHabit('one'));

      final snapshot = await repository.load();
      expect(snapshot.habits.map((value) => value.id), <String>['two']);
      expect(snapshot.entries, isEmpty);
    });

    test('rolls both keys back when the second write fails', () async {
      final originalHabitJson = jsonEncode(<Map<String, Object?>>[
        habit('original').toMap(),
      ]);
      final store = _FailingStore(<String, Object?>{
        KeyValueHabitRepository.habitsKey: originalHabitJson,
        KeyValueHabitRepository.entriesKey: '[]',
      });
      final repository = KeyValueHabitRepository(store);

      await expectLater(
        repository.transact((draft) => draft.upsertHabit(habit('new'))),
        throwsA(isA<HabitRepositoryException>()),
      );

      expect(
        await store.read(KeyValueHabitRepository.habitsKey),
        originalHabitJson,
      );
      expect(await store.read(KeyValueHabitRepository.entriesKey), '[]');
    });

    test(
      'serializes concurrent mutations instead of dropping an update',
      () async {
        final store = InMemoryKeyValueStore();
        final repository = KeyValueHabitRepository(store);
        final firstMayFinish = Completer<void>();
        final firstStarted = Completer<void>();

        final first = repository.transact((draft) async {
          draft.upsertHabit(habit('one'));
          firstStarted.complete();
          await firstMayFinish.future;
        });
        await firstStarted.future;
        final second = repository.transact(
          (draft) => draft.upsertHabit(habit('two')),
        );
        firstMayFinish.complete();
        await Future.wait(<Future<void>>[first, second]);

        final snapshot = await repository.load();
        expect(snapshot.habits.map((value) => value.id), <String>[
          'two',
          'one',
        ]);
      },
    );
  });
}

final class _FailingStore implements KeyValueStore {
  _FailingStore(Map<String, Object?> values)
    : _delegate = InMemoryKeyValueStore(values);

  final InMemoryKeyValueStore _delegate;
  var _writes = 0;

  @override
  Future<bool> contains(String key) => _delegate.contains(key);

  @override
  Future<Object?> read(String key) => _delegate.read(key);

  @override
  Future<bool> remove(String key) => _delegate.remove(key);

  @override
  Future<Map<String, Object?>> snapshot() => _delegate.snapshot();

  @override
  Future<void> write(String key, Object value) async {
    _writes++;
    if (_writes == 2) throw StateError('simulated second-write failure');
    await _delegate.write(key, value);
  }
}
