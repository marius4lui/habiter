import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/today/application/today_query.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/widgets/daily_progress_card.dart';
import 'package:habiter/widgets/bento_habit_card.dart';

void main() {
  final friday = LocalDate(2026, 8, 14);

  test('today query includes only active habits scheduled for the date', () {
    final snapshot = TodayQuery.forDate(
      date: friday,
      habits: <Habit>[
        _habit('daily', HabitFrequency.daily),
        _habit('friday', HabitFrequency.custom, customDays: <int>[5]),
        _habit('monday', HabitFrequency.custom, customDays: <int>[1]),
        _habit('archived', HabitFrequency.daily, active: false),
      ],
      entries: <HabitEntry>[],
    );

    expect(snapshot.scheduled.map((habit) => habit.id), <String>[
      'daily',
      'friday',
    ]);
    expect(snapshot.pending, hasLength(2));
    expect(snapshot.progress, 0);
  });

  test('today query separates completed work and computes progress', () {
    final snapshot = TodayQuery.forDate(
      date: friday,
      habits: <Habit>[
        _habit('daily', HabitFrequency.daily),
        _habit('weekly', HabitFrequency.weekly, target: 3),
      ],
      entries: <HabitEntry>[_entry('daily', friday.toString())],
    );

    expect(snapshot.completed.single.id, 'daily');
    expect(snapshot.pending.single.id, 'weekly');
    expect(snapshot.progress, 0.5);
  });

  test(
    'flexible weekly target stops being pending after three distinct days',
    () {
      final thursday = LocalDate(2026, 8, 20);
      final habit = _habit('weekly', HabitFrequency.weekly, target: 3);
      final entries = <HabitEntry>[
        _entry('weekly', '2026-08-17'),
        _entry('weekly', '2026-08-18'),
        _entry('weekly', '2026-08-19'),
        _entry('weekly', '2026-08-19'),
      ];

      final reached = TodayQuery.forDate(
        date: thursday,
        habits: <Habit>[habit],
        entries: entries,
      );
      final reopened = TodayQuery.forDate(
        date: thursday,
        habits: <Habit>[habit],
        entries: entries.take(2),
      );
      final nextMonday = TodayQuery.forDate(
        date: LocalDate(2026, 8, 24),
        habits: <Habit>[habit],
        entries: entries,
      );

      expect(reached.scheduled, isEmpty);
      expect(reached.progressFor('weekly')!.completed, 3);
      expect(reached.progressFor('weekly')!.targetReached, isTrue);
      expect(reopened.pending.single.id, 'weekly');
      expect(reopened.progressFor('weekly')!.remaining, 1);
      expect(nextMonday.pending.single.id, 'weekly');
      expect(nextMonday.progressFor('weekly')!.completed, 0);
    },
  );

  testWidgets('progress card survives 320px and 200 percent text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: DailyProgressCard(
                progress: 0.5,
                completedCount: 1,
                totalCount: 2,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('pending habit exposes one-tap completion', (tester) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 260,
            child: BentoHabitCard(
              habit: _habit('daily', HabitFrequency.daily),
              onComplete: () => completions++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.check_rounded));
    expect(completions, 1);
  });
}

Habit _habit(
  String id,
  HabitFrequency frequency, {
  List<int>? customDays,
  int target = 1,
  bool active = true,
}) => Habit(
  id: id,
  name: id,
  color: '#285943',
  icon: 'H',
  frequency: frequency,
  targetCount: target,
  category: 'Test',
  customDays: customDays,
  createdAt: DateTime.utc(2026),
  isActive: active,
);

HabitEntry _entry(String habitId, String date) => HabitEntry(
  id: 'entry-$habitId',
  habitId: habitId,
  date: date,
  completed: true,
  count: 1,
  timestamp: DateTime.utc(2026, 8, 14),
);
