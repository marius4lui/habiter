import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:habiter/core/time/clock.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/history/application/habit_lifecycle_use_case.dart';
import 'package:habiter/features/history/application/habit_lifecycle_reminder_gateway.dart';
import 'package:habiter/features/history/application/habit_timeline.dart';
import 'package:habiter/features/history/presentation/habit_lifecycle_panel.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:habiter/utils/habit_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  final pausedAt = DateTime.utc(2026, 8, 10, 12);
  final resumedAt = DateTime.utc(2026, 8, 12, 8);

  test('pause metadata roundtrips without changing legacy defaults', () {
    final habit = _habit().copyWith(
      isActive: false,
      pauses: <HabitPause>[HabitPause(startedAt: pausedAt)],
    );

    final decoded = Habit.fromMap(habit.toMap());

    expect(decoded.lifecycleStatus, HabitLifecycleStatus.paused);
    expect(decoded.pauses.single.startedAt, pausedAt);
    expect(decoded.pauses.single.endedAt, isNull);
    expect(
      Habit.fromMap(_habit().toMap()).lifecycleStatus,
      HabitLifecycleStatus.active,
    );
  });

  test(
    'pause, resume, archive and restore preserve a forgiving timeline',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      await repository.transact((draft) => draft.upsertHabit(_habit()));
      final lifecycle = HabitLifecycleUseCase(
        repository: repository,
        clock: _SequenceClock(<DateTime>[
          pausedAt,
          resumedAt,
          resumedAt.add(const Duration(days: 1)),
          resumedAt.add(const Duration(days: 2)),
        ]),
      );

      expect((await lifecycle.pause('habit-1')).changed, isTrue);
      expect(
        (await repository.load()).habits.single.lifecycleStatus,
        HabitLifecycleStatus.paused,
      );
      expect((await lifecycle.resume('habit-1')).changed, isTrue);
      var habit = (await repository.load()).habits.single;
      expect(habit.lifecycleStatus, HabitLifecycleStatus.active);
      expect(habit.pauses.single.endedAt, resumedAt);

      await lifecycle.archive('habit-1');
      habit = (await repository.load()).habits.single;
      expect(habit.lifecycleStatus, HabitLifecycleStatus.archived);
      await lifecycle.restore('habit-1');
      habit = (await repository.load()).habits.single;
      expect(habit.lifecycleStatus, HabitLifecycleStatus.active);

      final timeline = HabitTimeline.forHabit(habit);
      expect(timeline.map((event) => event.type), <HabitTimelineEventType>[
        HabitTimelineEventType.created,
        HabitTimelineEventType.paused,
        HabitTimelineEventType.resumed,
        HabitTimelineEventType.archived,
        HabitTimelineEventType.restored,
      ]);
    },
  );

  test(
    'pause ranges are excluded from stats and delete remains cascading',
    () async {
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      final habit = _habit().copyWith(
        pauses: <HabitPause>[
          HabitPause(startedAt: pausedAt, endedAt: resumedAt),
        ],
      );
      await repository.transact((draft) {
        draft.upsertHabit(habit);
        draft.upsertEntry(_entry('2026-08-09'));
        draft.upsertEntry(_entry('2026-08-11'));
      });

      expect(
        calculateHabitStats(
          habit,
          (await repository.load()).entries,
        ).totalCompletions,
        1,
      );
      expect(habit.isPausedOn('2026-08-10'), isTrue);
      expect(habit.isPausedOn('2026-08-11'), isTrue);
      expect(habit.isPausedOn('2026-08-12'), isFalse);
      final lifecycle = HabitLifecycleUseCase(
        repository: repository,
        clock: _SequenceClock(<DateTime>[resumedAt]),
      );
      await lifecycle.delete('habit-1');
      final snapshot = await repository.load();
      expect(snapshot.habits, isEmpty);
      expect(snapshot.entries, isEmpty);
    },
  );

  test(
    'committed lifecycle transitions cancel and restore eligible reminders',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
      await repository.transact((draft) => draft.upsertHabit(_habit()));
      final reminders = _RecordingLifecycleReminders();
      final provider = HabitProvider(
        repository: repository,
        clock: _SequenceClock(<DateTime>[pausedAt, resumedAt]),
        lifecycleReminders: reminders,
      );
      addTearDown(provider.dispose);
      await provider.load();
      await provider.updateHabit(
        'habit-1',
        provider.habits.single.copyWith(
          notificationEnabled: true,
          notificationTime: '09:00',
        ),
      );

      await provider.pauseHabit('habit-1');
      await provider.resumeHabit('habit-1');
      await provider.resumeHabit('habit-1');

      expect(reminders.calls, <String>['cancel:habit-1', 'schedule:habit-1']);
    },
  );

  testWidgets(
    'lifecycle panel is scroll-safe at 320px/200% and confirms deletion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final callbacks = <String>[];
      final paused = _habit().copyWith(
        isActive: false,
        pauses: <HabitPause>[HabitPause(startedAt: pausedAt)],
      );
      final archived = Habit(
        id: 'habit-2',
        name: 'Archived reading habit with a long localized title',
        color: '#000000',
        icon: 'R',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        category: 'Learning',
        createdAt: DateTime.utc(2026, 8, 1),
        isActive: false,
        archivedAt: pausedAt,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: HabitLifecyclePanel(
                  habits: <Habit>[paused, archived],
                  onResume: (id) async => callbacks.add('resume:$id'),
                  onRestore: (id) async => callbacks.add('restore:$id'),
                  onDelete: (id) async => callbacks.add('delete:$id'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('habit-lifecycle-panel')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Habit fortsetzen'));
      await tester.pump();
      expect(callbacks, <String>['resume:habit-1']);

      await tester.ensureVisible(find.byTooltip('Habit wiederherstellen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Habit wiederherstellen'));
      await tester.pump();
      expect(callbacks, <String>['resume:habit-1', 'restore:habit-2']);

      await tester.ensureVisible(find.byTooltip('Löschen').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Löschen').last);
      await tester.pumpAndSettle();
      expect(find.text('Habit löschen'), findsOneWidget);
      expect(callbacks.where((value) => value.startsWith('delete:')), isEmpty);
      await tester.tap(find.text('Löschen').last);
      await tester.pumpAndSettle();
      expect(callbacks.last, 'delete:habit-2');
      expect(tester.takeException(), isNull);
    },
  );
}

Habit _habit() => Habit(
  id: 'habit-1',
  name: 'Walk',
  color: '#000000',
  icon: 'W',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Health',
  createdAt: DateTime.utc(2026, 8, 1),
  isActive: true,
);

HabitEntry _entry(String date) => HabitEntry(
  id: 'entry-$date',
  habitId: 'habit-1',
  date: date,
  completed: true,
  count: 1,
  timestamp: DateTime.parse('${date}T08:00:00Z'),
);

final class _SequenceClock implements Clock {
  _SequenceClock(this.values);
  final List<DateTime> values;
  @override
  DateTime now() => values.length == 1 ? values.single : values.removeAt(0);
}

final class _RecordingLifecycleReminders
    implements HabitLifecycleReminderGateway {
  final List<String> calls = <String>[];

  @override
  Future<void> cancelForHabit(String habitId) async {
    calls.add('cancel:$habitId');
  }

  @override
  Future<void> scheduleForHabit(Habit habit) async {
    calls.add('schedule:${habit.id}');
  }
}
