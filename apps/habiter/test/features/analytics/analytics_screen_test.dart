import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:habiter/screens/analytics_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('selected habit with little data gets a truthful empty state', (
    tester,
  ) async {
    final provider = await _provider(historyDays: 0);
    addTearDown(provider.dispose);
    await tester.pumpWidget(_app(provider, const Locale('de')));
    await tester.pumpAndSettle();

    expect(find.text('Noch nicht genug Verlauf'), findsOneWidget);
    expect(
      find.text('Tracke ein Habit, um den Wochenfortschritt zu sehen.'),
      findsNothing,
    );
    expect(find.text('Diese Woche'), findsOneWidget);
    expect(find.text('1 von 1 geplanten Einheiten'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal history exposes week, thirty-day trend and semantics', (
    tester,
  ) async {
    final provider = await _provider(historyDays: 35);
    addTearDown(provider.dispose);
    await tester.pumpWidget(_app(provider, const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'This week: \d+ of 7 planned')),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<HabitProvider> _provider({required int historyDays}) async {
  final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
  final now = DateTime(2026, 8, 16, 12);
  final habit = Habit(
    id: 'habit',
    name: 'Walk',
    color: '#467B68',
    icon: '🚶',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    category: 'Health',
    createdAt: DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: historyDays)),
    isActive: true,
  );
  await repository.transact((draft) {
    draft.upsertHabit(habit);
    for (var offset = historyDays; offset >= 0; offset -= 2) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: offset));
      final dateString =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      draft.upsertEntry(
        HabitEntry(
          id: 'entry-$dateString',
          habitId: habit.id,
          date: dateString,
          completed: true,
          count: 1,
          timestamp: date,
        ),
      );
    }
  });
  final provider = HabitProvider(repository: repository, clock: FakeClock(now));
  await provider.load();
  return provider;
}

Widget _app(HabitProvider provider, Locale locale) =>
    ChangeNotifierProvider<HabitProvider>.value(
      value: provider,
      child: MaterialApp(
        locale: locale,
        theme: HabiterTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AnalyticsScreen(),
      ),
    );
