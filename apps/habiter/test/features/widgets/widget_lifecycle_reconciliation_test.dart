import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/widgets/application/widget_lifecycle_coordinator.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test('external state is rehydrated before runtime and widget sync', () async {
    final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
    await repository.transact((draft) {
      draft.upsertHabit(_habit());
      draft.upsertEntry(_entry());
    });
    final events = <String>[];
    late HabitProvider provider;
    provider = HabitProvider(
      repository: repository,
      delay: (_) async {},
      reconcileRuntime:
          ({
            required habits,
            required entries,
            required processActions,
            required refreshTimeZone,
          }) async {
            events.add('runtime:${habits.length}:${entries.length}');
            expect(processActions, isTrue);
            expect(refreshTimeZone, isTrue);
          },
      synchronizeWidget: () async {
        events.add(
          'widget:${provider.habits.length}:${provider.habitEntries.length}',
        );
      },
    )..addListener(() => events.add('state'));

    await provider.reconcileExternalHabitState();

    expect(provider.habits.single.id, 'habit-1');
    expect(provider.habitEntries.single.completed, isTrue);
    expect(events, <String>['state', 'runtime:1:1', 'widget:1:1']);
  });

  test(
    'write racing with reconciliation converges on latest revision',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      await repository.transact((draft) => draft.upsertHabit(_habit()));
      final settle = Completer<void>();
      var delayCalls = 0;
      var runtimeCalls = 0;
      var widgetCalls = 0;
      final provider = HabitProvider(
        repository: repository,
        delay: (_) async {
          delayCalls++;
          if (delayCalls == 1) await settle.future;
        },
        reconcileRuntime:
            ({
              required habits,
              required entries,
              required processActions,
              required refreshTimeZone,
            }) async {
              runtimeCalls++;
            },
        synchronizeWidget: () async => widgetCalls++,
      );

      final reconciliation = provider.reconcileExternalHabitState();
      await Future<void>.delayed(Duration.zero);
      await repository.transact((draft) => draft.upsertEntry(_entry()));
      settle.complete();
      await reconciliation;

      expect(provider.habitEntries.single.completed, isTrue);
      expect(runtimeCalls, 2);
      expect(widgetCalls, 2);
    },
  );

  test('overlapping lifecycle requests are serialized and drained', () async {
    final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
    await repository.transact((draft) => draft.upsertHabit(_habit()));
    final settle = Completer<void>();
    var delayCalls = 0;
    var runtimeCalls = 0;
    final provider = HabitProvider(
      repository: repository,
      delay: (_) async {
        delayCalls++;
        if (delayCalls == 1) await settle.future;
      },
      reconcileRuntime:
          ({
            required habits,
            required entries,
            required processActions,
            required refreshTimeZone,
          }) async {
            runtimeCalls++;
          },
      synchronizeWidget: () async {},
    );

    final first = provider.reconcileExternalHabitState();
    await Future<void>.delayed(Duration.zero);
    final second = provider.reconcileExternalHabitState();
    settle.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(runtimeCalls, 2);
  });

  test('lifecycle coordinator orders foreground and background work', () async {
    final events = <String>[];
    final coordinator = WidgetLifecycleCoordinator(
      reconcileForeground: () async => events.add('foreground'),
      publishBackground: () async => events.add('background'),
    );

    await coordinator.handle(AppLifecycleState.resumed);
    await coordinator.handle(AppLifecycleState.inactive);
    await coordinator.handle(AppLifecycleState.hidden);
    await coordinator.handle(AppLifecycleState.paused);
    await coordinator.handle(AppLifecycleState.detached);
    await coordinator.handle(AppLifecycleState.resumed);

    expect(events, <String>['foreground', 'background', 'foreground']);
  });

  test('lifecycle failures are contained and later work still runs', () async {
    final errors = <Object>[];
    var backgroundCalls = 0;
    final coordinator = WidgetLifecycleCoordinator(
      reconcileForeground: () async => throw StateError('resume failed'),
      publishBackground: () async => backgroundCalls++,
      onError: (error, _) => errors.add(error),
    );

    await coordinator.handle(AppLifecycleState.resumed);
    await coordinator.handle(AppLifecycleState.paused);

    expect(errors.single, isA<StateError>());
    expect(backgroundCalls, 1);
  });
}

Habit _habit() => Habit(
  id: 'habit-1',
  name: 'Read',
  color: '#285943',
  icon: 'R',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Test',
  createdAt: DateTime.utc(2026, 8, 17),
  isActive: true,
);

HabitEntry _entry() => HabitEntry(
  id: 'entry-1',
  habitId: 'habit-1',
  date: '2026-08-17',
  completed: true,
  count: 1,
  timestamp: DateTime.utc(2026, 8, 17, 12),
);
