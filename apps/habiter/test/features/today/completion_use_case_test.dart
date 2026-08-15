import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/ids/id_generator.dart';
import 'package:habiter/core/time/clock.dart';
import 'package:habiter/features/habits/application/habit_repository.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/today/application/completion_use_case.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  final completedAt = DateTime.utc(2026, 8, 14, 23, 59, 59);

  test(
    'concurrent completion is idempotent and commits one occurrence',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      await repository.transact(
        (draft) => draft.upsertHabit(_habit(target: 3)),
      );
      final useCase = CompletionUseCase(
        repository: repository,
        ids: _Ids(<String>['entry-1']),
        clock: _Clock(completedAt),
      );

      final results = await Future.wait(<Future<CompletionResult>>[
        useCase.complete('habit-1', '2026-08-14'),
        useCase.complete('habit-1', '2026-08-14'),
      ]);
      final snapshot = await repository.load();

      expect(results.where((result) => result.changed), hasLength(1));
      expect(snapshot.entries, hasLength(1));
      expect(snapshot.entries.single.id, 'entry-1');
      expect(snapshot.entries.single.count, 3);
      expect(snapshot.entries.single.completed, isTrue);
    },
  );

  test(
    'undo restores the prior occurrence and cannot overwrite newer data',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      await repository.transact((draft) {
        draft.upsertHabit(_habit());
        draft.upsertEntry(_entry(completed: false, count: 0));
      });
      final useCase = CompletionUseCase(
        repository: repository,
        ids: _Ids(<String>[]),
        clock: _Clock(completedAt),
      );

      final completion = await useCase.complete('habit-1', '2026-08-14');
      expect((await useCase.undo(completion.undoToken!)).changed, isTrue);
      expect((await repository.load()).entries.single.completed, isFalse);

      final second = await useCase.complete('habit-1', '2026-08-14');
      await repository.transact(
        (draft) => draft.upsertEntry(
          _entry(
            completed: true,
            count: 7,
            timestamp: completedAt.add(const Duration(seconds: 1)),
          ),
        ),
      );
      expect((await useCase.undo(second.undoToken!)).changed, isFalse);
      expect((await repository.load()).entries.single.count, 7);
    },
  );

  test('undo removes a newly created occurrence', () async {
    final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
    await repository.transact((draft) => draft.upsertHabit(_habit()));
    final useCase = CompletionUseCase(
      repository: repository,
      ids: _Ids(<String>['entry-1']),
      clock: _Clock(completedAt),
    );

    final completion = await useCase.complete('habit-1', '2026-08-15');
    await useCase.undo(completion.undoToken!);

    expect((await repository.load()).entries, isEmpty);
  });

  test('a failed write emits neither success nor refresh state', () async {
    final useCase = CompletionUseCase(
      repository: _FailingRepository(),
      ids: _Ids(<String>['entry-1']),
      clock: _Clock(completedAt),
    );

    await expectLater(
      useCase.complete('habit-1', '2026-08-14'),
      throwsA(isA<StateError>()),
    );
  });
}

Habit _habit({int target = 1}) => Habit(
  id: 'habit-1',
  name: 'Walk',
  color: '#000000',
  icon: 'W',
  frequency: HabitFrequency.daily,
  targetCount: target,
  category: 'Health',
  createdAt: DateTime.utc(2026, 1, 1),
  isActive: true,
);

HabitEntry _entry({
  required bool completed,
  required int count,
  DateTime? timestamp,
}) => HabitEntry(
  id: 'entry-existing',
  habitId: 'habit-1',
  date: '2026-08-14',
  completed: completed,
  count: count,
  timestamp: timestamp ?? DateTime.utc(2026, 8, 14, 8),
);

final class _Clock implements Clock {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

final class _Ids implements IdGenerator {
  _Ids(this.values);
  final List<String> values;
  @override
  String next() => values.removeAt(0);
}

final class _FailingRepository implements HabitRepository {
  @override
  Future<HabitRepositorySnapshot> load() async => HabitRepositorySnapshot(
    habits: <Habit>[_habit()],
    entries: const <HabitEntry>[],
  );

  @override
  Future<void> transact(
    FutureOr<void> Function(HabitRepositoryDraft draft) mutation,
  ) async {
    throw StateError('disk full');
  }
}
