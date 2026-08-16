import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/history/application/habit_lifecycle_reminder_gateway.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:habiter/providers/settings_provider.dart';
import 'package:habiter/screens/analytics_screen.dart';
import 'package:habiter/screens/home_screen.dart';
import 'package:habiter/screens/settings_screen.dart';
import 'package:habiter/widgets/add_habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Today remains actionable across target phone widths', (
    tester,
  ) async {
    final provider = await _providerWithHabits();
    addTearDown(provider.dispose);
    for (final width in <double>[320, 360, 390, 412]) {
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _app(provider: provider, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('NEXT UP'), findsOneWidget);
      expect(find.byKey(const Key('add-habit-fab')), findsOneWidget);
      expect(find.byKey(const Key('habit-lifecycle-panel')), findsNothing);
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Today reveals inactive habits compactly and collapses the FAB', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithHabits();
    addTearDown(provider.dispose);
    await provider.pauseHabit(provider.habits.last.id);

    await tester.pumpWidget(_app(provider: provider, home: const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('1 paused or archived habit'), findsOneWidget);
    expect(find.byKey(const ValueKey('extended-add-fab')), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('compact-add-fab')), findsOneWidget);
  });

  testWidgets('Today completion stays one tap with an undo affordance', (
    tester,
  ) async {
    final provider = await _providerWithHabits();
    addTearDown(provider.dispose);
    await tester.pumpWidget(_app(provider: provider, home: const HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark as complete').first);
    await tester.pumpAndSettle();

    expect(
      provider.habitEntries.where((entry) => entry.completed),
      hasLength(1),
    );
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('core screens support dark theme and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithHabits();
    final settings = SettingsProvider();
    addTearDown(provider.dispose);
    addTearDown(settings.dispose);

    for (final screen in <Widget>[
      const HomeScreen(),
      const AnalyticsScreen(),
      const SettingsScreen(),
    ]) {
      await tester.pumpWidget(
        _app(
          provider: provider,
          settings: settings,
          home: screen,
          dark: true,
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: screen.runtimeType.toString(),
      );
    }
  });

  testWidgets('guided editor keeps primary controls reachable at 200 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithHabits();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      _app(
        provider: provider,
        textScale: 2,
        home: const Scaffold(body: AddHabitSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.byKey(const Key('template-search')), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings light visual contract', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithHabits();
    final settings = SettingsProvider();
    addTearDown(provider.dispose);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      _app(
        provider: provider,
        settings: settings,
        home: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_light.png'),
    );
  });

  testWidgets('guided editor light visual contract', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithHabits();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      _app(
        provider: provider,
        home: const Scaffold(body: AddHabitSheet()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AddHabitSheet),
      matchesGoldenFile('goldens/habit_editor_light.png'),
    );
  });

  testWidgets('creation rhythm and review visual contracts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithHabits();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      _app(
        provider: provider,
        home: const Scaffold(body: AddHabitSheet()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('template-workout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-habit-action')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AddHabitSheet),
      matchesGoldenFile('goldens/habit_editor_rhythm_light.png'),
    );

    await tester.tap(find.byKey(const Key('create-habit-action')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AddHabitSheet),
      matchesGoldenFile('goldens/habit_editor_review_light.png'),
    );
  });

  testWidgets('analytics light visual contract', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithHabits();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      _app(provider: provider, home: const AnalyticsScreen()),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AnalyticsScreen),
      matchesGoldenFile('goldens/analytics_light.png'),
    );
  });

  testWidgets('creation template dark visual contract', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithHabits();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      _app(
        provider: provider,
        dark: true,
        home: const Scaffold(body: AddHabitSheet()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AddHabitSheet),
      matchesGoldenFile('goldens/habit_editor_dark.png'),
    );
  });
}

Future<HabitProvider> _providerWithHabits() async {
  final repository = KeyValueHabitRepository(InMemoryKeyValueStore());
  final provider = HabitProvider(
    repository: repository,
    lifecycleReminders: const _NoLifecycleReminders(),
  );
  await provider.load();
  await provider.addHabit(
    name: 'Drink water',
    description: 'One glass',
    category: 'Health',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    color: '#356859',
    icon: '💧',
  );
  await provider.addHabit(
    name: 'Read',
    category: 'Learning',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    color: '#8B5D48',
    icon: '📚',
  );
  return provider;
}

Widget _app({
  required HabitProvider provider,
  required Widget home,
  SettingsProvider? settings,
  bool dark = false,
  double textScale = 1,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<HabitProvider>.value(value: provider),
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings ?? SettingsProvider(),
    ),
    Provider<HapticGateway>.value(value: const _NoHaptics()),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    theme: HabiterTheme.light(),
    darkTheme: HabiterTheme.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  ),
);

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
