import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/habits/presentation/templates/habit_template.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:habiter/widgets/add_habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fakes/in_memory_key_value_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('template catalog has stable ids and meaningful smart defaults', () {
    expect(
      HabitTemplate.catalog.map((template) => template.id).toSet(),
      hasLength(16),
    );
    final workout = HabitTemplate.catalog.singleWhere(
      (template) => template.id == 'workout',
    );
    expect(workout.category, HabitCategories.fitness);
    expect(workout.frequency, HabitFrequency.weekly);
    expect(workout.targetCount, 3);
    expect(workout.icon, '🏋️');
  });

  testWidgets('template selection carries smart defaults through creation', (
    tester,
  ) async {
    final haptics = _RecordingHaptics();
    final provider = await _provider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      _app(provider: provider, haptics: haptics, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('template-workout')));
    await tester.pumpAndSettle();
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('Fitness · 3× per week'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-habit-action')));
    await tester.pumpAndSettle();
    expect(find.text('How often?'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('target-3'))).selected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('target-4')));
    await tester.tap(find.byKey(const Key('create-habit-action')));
    await tester.pumpAndSettle();
    expect(find.text('Would you like a reminder?'), findsOneWidget);
    expect(find.text('4× per week · Fitness'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reminder-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Scheduled for 20:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reminder-switch')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-habit-action')));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Ready.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));

    expect(provider.habits, hasLength(1));
    final created = provider.habits.single;
    expect(created.name, 'Workout');
    expect(created.category, HabitCategories.fitness);
    expect(created.frequency, HabitFrequency.weekly);
    expect(created.targetCount, 4);
    expect(created.notificationEnabled, isFalse);
    expect(haptics.selections, greaterThanOrEqualTo(4));
    expect(haptics.successes, 1);
  });

  testWidgets('search filters templates and seeds the custom path', (
    tester,
  ) async {
    final provider = await _provider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(_app(provider: provider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('template-search')), 'journal');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('template-read')), findsNothing);
    expect(find.text('Create your own habit "journal"'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('custom-habit-action')));
    await tester.ensureVisible(find.byKey(const Key('custom-habit-action')));
    await tester.tap(find.byKey(const Key('custom-habit-action')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('habit-name-field')))
          .controller
          ?.text,
      'journal',
    );
    await tester.tap(find.byKey(const Key('create-habit-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('frequency-custom')));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<FilterChip>(find.byType(FilterChip)).first.key,
      const ValueKey('weekday-7'),
    );
  });

  testWidgets('custom weekdays and back navigation preserve the draft', (
    tester,
  ) async {
    final provider = await _provider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      _app(provider: provider, locale: const Locale('de')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gesundheit'), findsOneWidget);
    expect(find.text('Health'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('template-search')),
      'Tagebuch',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('custom-habit-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-habit-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('frequency-custom')));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<FilterChip>(find.byType(FilterChip)).first.key,
      const ValueKey('weekday-1'),
    );
    await tester.tap(find.byKey(const Key('weekday-1')));
    await tester.tap(find.byKey(const Key('weekday-3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Tagebuch'), findsWidgets);

    await tester.tap(find.byKey(const Key('create-habit-action')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilterChip>(find.byKey(const Key('weekday-1'))).selected,
      isTrue,
    );
    expect(
      tester.widget<FilterChip>(find.byKey(const Key('weekday-3'))).selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom name and CTA remain reachable above keyboard insets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final provider = await _provider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(_app(provider: provider));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('template-search')), 'Journal');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('custom-habit-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('habit-name-field')), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('habit-name-field')), findsOneWidget);
    expect(find.byKey(const Key('create-habit-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing stays direct and preserves persisted lifecycle data', (
    tester,
  ) async {
    final provider = await _provider();
    addTearDown(provider.dispose);
    await provider.addHabit(
      name: 'Read',
      category: HabitCategories.learning,
      frequency: HabitFrequency.daily,
      targetCount: 1,
      color: '#7B61A8',
      icon: '📚',
    );
    final habit = provider.habits.single;
    await tester.pumpWidget(_app(provider: provider, habit: habit));
    await tester.pumpAndSettle();

    expect(find.textContaining('Step '), findsNothing);
    expect(find.byKey(const Key('update-habit-action')), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Read books');
    await tester.tap(find.byKey(const Key('update-habit-action')));
    await tester.pumpAndSettle();

    expect(provider.habits.single.name, 'Read books');
    expect(provider.habits.single.createdAt, habit.createdAt);
  });
}

Future<HabitProvider> _provider() async {
  final provider = HabitProvider(
    repository: KeyValueHabitRepository(InMemoryKeyValueStore()),
  );
  await provider.load();
  return provider;
}

Widget _app({
  required HabitProvider provider,
  Locale locale = const Locale('en'),
  Habit? habit,
  _RecordingHaptics? haptics,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<HabitProvider>.value(value: provider),
    Provider<HapticGateway>.value(value: haptics ?? _RecordingHaptics()),
  ],
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
    home: Scaffold(body: AddHabitSheet(habit: habit)),
  ),
);

class _RecordingHaptics implements HapticGateway {
  int selections = 0;
  int successes = 0;

  @override
  Future<void> selection() async => selections++;

  @override
  Future<void> success() async => successes++;
}
