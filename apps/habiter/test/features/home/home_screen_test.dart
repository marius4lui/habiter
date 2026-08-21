import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/history/application/habit_lifecycle_reminder_gateway.dart';
import 'package:habiter/features/home/application/habit_hub_model.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:habiter/providers/settings_provider.dart';
import 'package:habiter/screens/home_screen.dart';
import 'package:habiter/widgets/add_habit_sheet.dart';
import 'package:habiter/widgets/habit_detail_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('empty hub creates the first habit in the existing editor', (
    tester,
  ) async {
    final fixture = await _Fixture.empty();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('habit-hub-empty-state')), findsOneWidget);
    expect(find.text('Make space for a new habit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-first-habit')));
    await tester.pumpAndSettle();

    expect(find.byType(AddHabitSheet), findsOneWidget);
  });

  testWidgets('hero shows newest active habit and opens existing details', (
    tester,
  ) async {
    final fixture = await _Fixture.withHabits(includeArchived: true);
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    expect(find.text('Newest active'), findsOneWidget);
    expect(find.text('Archived newest'), findsNothing);

    await tester.tap(find.text('Newest active'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitDetailDialog), findsOneWidget);
  });

  testWidgets(
    'hero renders a stable custom schedule without implementation text',
    (tester) async {
      final custom = await _Fixture.withSchedule(
        frequency: HabitFrequency.custom,
        targetCount: 1,
        customDays: const <int>[1, 3, 5],
      );
      addTearDown(custom.dispose);
      await tester.pumpWidget(custom.app());
      await tester.pumpAndSettle();

      final schedule = tester.widget<Text>(
        find.byKey(const Key('latest-habit-schedule')),
      );
      expect(schedule.data, '1 on 3 days');
      expect(schedule.data, isNot(contains('Closure')));
      expect(schedule.data, isNot(contains('Function')));
      expect(schedule.data, isNot(contains('onDays')));
    },
  );

  testWidgets('top controls use the same destination callback as the wheel', (
    tester,
  ) async {
    final fixture = await _Fixture.withHabits();
    addTearDown(fixture.dispose);
    final opened = <HabitHubDestination>[];
    await tester.pumpWidget(fixture.app(onOpenDestination: opened.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hub-app-lock-action')));
    await tester.tap(find.byKey(const Key('hub-settings-action')));

    expect(opened, <HabitHubDestination>[
      HabitHubDestination.appLock,
      HabitHubDestination.settings,
    ]);
  });

  testWidgets('hub light visual contract at 390 by 844', (tester) async {
    await _expectGolden(
      tester,
      size: const Size(390, 844),
      dark: false,
      file: 'goldens/habit_hub_light_390.png',
    );
  });

  testWidgets('hub dark visual contract at 390 by 844', (tester) async {
    await _expectGolden(
      tester,
      size: const Size(390, 844),
      dark: true,
      file: 'goldens/habit_hub_dark_390.png',
    );
  });

  testWidgets('hub compact visual contract at 320 by 720', (tester) async {
    await _expectGolden(
      tester,
      size: const Size(320, 720),
      dark: false,
      file: 'goldens/habit_hub_light_320.png',
    );
  });
}

Future<void> _expectGolden(
  WidgetTester tester, {
  required Size size,
  required bool dark,
  required String file,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixture = await _Fixture.withHabits();
  addTearDown(fixture.dispose);
  await tester.pumpWidget(fixture.app(dark: dark, disableAnimations: true));
  await tester.pumpAndSettle();

  await expectLater(find.byType(HomeScreen), matchesGoldenFile(file));
}

final class _Fixture {
  _Fixture(this.provider, this.settings);

  final HabitProvider provider;
  final SettingsProvider settings;

  static Future<_Fixture> empty() async {
    final provider = HabitProvider(
      repository: KeyValueHabitRepository(InMemoryKeyValueStore()),
      lifecycleReminders: const _NoLifecycleReminders(),
      clock: FakeClock(DateTime(2026, 8, 20, 12)),
    );
    await provider.load();
    return _Fixture(provider, SettingsProvider());
  }

  static Future<_Fixture> withHabits({bool includeArchived = false}) async {
    final clock = FakeClock(DateTime(2026, 8, 20, 12));
    final provider = HabitProvider(
      repository: KeyValueHabitRepository(InMemoryKeyValueStore()),
      lifecycleReminders: const _NoLifecycleReminders(),
      clock: clock,
    );
    await provider.load();
    await provider.addHabit(
      name: 'Older habit',
      category: 'Health',
      frequency: HabitFrequency.daily,
      targetCount: 1,
      color: '#6B8E7A',
      icon: '🌿',
    );
    clock.advance(const Duration(minutes: 1));
    await provider.addHabit(
      name: 'Newest active',
      description: 'A quiet next step',
      category: 'Mindfulness',
      frequency: HabitFrequency.daily,
      targetCount: 1,
      color: '#7AB8A8',
      icon: '🫧',
    );
    if (includeArchived) {
      clock.advance(const Duration(minutes: 1));
      final archivedId = await provider.addHabit(
        name: 'Archived newest',
        category: 'Other',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        color: '#C88787',
        icon: 'A',
      );
      await provider.archiveHabit(archivedId);
    }
    return _Fixture(provider, SettingsProvider());
  }

  static Future<_Fixture> withSchedule({
    required HabitFrequency frequency,
    required int targetCount,
    List<int>? customDays,
  }) async {
    final provider = HabitProvider(
      repository: KeyValueHabitRepository(InMemoryKeyValueStore()),
      lifecycleReminders: const _NoLifecycleReminders(),
      clock: FakeClock(DateTime(2026, 8, 20, 12)),
    );
    await provider.load();
    await provider.addHabit(
      name: 'Training',
      category: 'Health',
      frequency: frequency,
      targetCount: targetCount,
      customDays: customDays,
      color: '#6B8E7A',
      icon: '🏋️',
    );
    return _Fixture(provider, SettingsProvider());
  }

  Widget app({
    bool dark = false,
    bool disableAnimations = false,
    ValueChanged<HabitHubDestination>? onOpenDestination,
  }) => MultiProvider(
    providers: [
      ChangeNotifierProvider<HabitProvider>.value(value: provider),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      Provider<HapticGateway>.value(value: const _NoHaptics()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      theme: HabiterTheme.light(),
      darkTheme: HabiterTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: HomeScreen(onOpenDestination: onOpenDestination),
    ),
  );

  void dispose() {
    provider.dispose();
    settings.dispose();
  }
}

class _NoHaptics implements HapticGateway {
  const _NoHaptics();

  @override
  Future<void> selection() async {}

  @override
  Future<void> success() async {}
}

class _NoLifecycleReminders implements HabitLifecycleReminderGateway {
  const _NoLifecycleReminders();

  @override
  Future<void> cancelForHabit(String habitId) async {}

  @override
  Future<void> scheduleForHabit(Habit habit) async {}
}
