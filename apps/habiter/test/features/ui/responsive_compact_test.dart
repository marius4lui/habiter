import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/habits/presentation/templates/habit_template.dart';
import 'package:habiter/features/history/application/habit_lifecycle_reminder_gateway.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
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

  testWidgets('Today remains actionable at compact low-height sizes', (
    tester,
  ) async {
    final provider = await _providerWithLongHabit();
    addTearDown(provider.dispose);

    for (final size in <Size>[const Size(320, 480), const Size(480, 320)]) {
      await _setViewport(tester, size);
      await tester.pumpWidget(
        _app(provider: provider, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('latest-habit-name')), findsOneWidget);
      expect(find.byKey(const Key('latest-habit-complete')), findsOneWidget);
      expect(find.byKey(const Key('habit-navigation-wheel')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('Today handles a long habit name at 320px and 200% text', (
    tester,
  ) async {
    final provider = await _providerWithLongHabit();
    addTearDown(provider.dispose);
    await _setViewport(tester, const Size(320, 480));

    await tester.pumpWidget(
      _app(
        provider: provider,
        textScaler: const TextScaler.linear(2),
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('latest-habit-name')), findsOneWidget);
    expect(find.byKey(const Key('latest-habit-complete')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('habit details stay scrollable with long text at 200%', (
    tester,
  ) async {
    final provider = await _providerWithLongHabit();
    addTearDown(provider.dispose);
    final habit = provider.habits.single;
    await _setViewport(tester, const Size(320, 480));

    await tester.pumpWidget(
      _app(
        provider: provider,
        textScaler: const TextScaler.linear(2),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => HabitDetailDialog(
                    habit: habit,
                    isCompleted: false,
                    onComplete: () {},
                    onArchive: () {},
                    onPause: () {},
                    onEdit: () {},
                  ),
                ),
                child: const Text('Open details'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitDetailDialog), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Archive'), 200);
    expect(find.text('Archive'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guided editor keeps its primary action on a short viewport', (
    tester,
  ) async {
    final provider = await _providerWithLongHabit();
    addTearDown(provider.dispose);
    await _setViewport(tester, const Size(320, 480));

    await tester.pumpWidget(
      _app(
        provider: provider,
        textScaler: const TextScaler.linear(2),
        home: const Scaffold(body: AddHabitSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddHabitSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    final search = find.byKey(
      const Key('template-search'),
      skipOffstage: false,
    );
    expect(search, findsOneWidget);
    final editorScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    final position = tester.state<ScrollableState>(editorScroll).position;
    expect(position.maxScrollExtent, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final grid = tester.widget<GridView>(
      find.byType(GridView, skipOffstage: false),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 1);
    expect(delegate.mainAxisExtent, 184);

    position.jumpTo(250.0.clamp(0, position.maxScrollExtent));
    await tester.pumpAndSettle();
    final custom = find.byKey(
      const Key('custom-habit-action'),
      skipOffstage: false,
    );
    await tester.ensureVisible(custom);
    await tester.pumpAndSettle();
    await tester.tap(custom);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-habit-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<HabitProvider> _providerWithLongHabit() async {
  final provider = HabitProvider(
    repository: KeyValueHabitRepository(InMemoryKeyValueStore()),
    lifecycleReminders: const _NoLifecycleReminders(),
    clock: FakeClock(DateTime(2026, 8, 21, 12)),
  );
  await provider.load();
  await provider.addHabit(
    name: 'Mindful movement before the beginning of every focused workday',
    description:
        'A deliberately long description that proves the detail presentation '
        'can grow vertically without hiding lifecycle actions.',
    category: HabitCategories.fitness,
    frequency: HabitFrequency.daily,
    targetCount: 1,
    color: '#467B68',
    icon: '🧘',
  );
  return provider;
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  required HabitProvider provider,
  required Widget home,
  TextScaler textScaler = TextScaler.noScaling,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<HabitProvider>.value(value: provider),
    Provider<HapticGateway>.value(value: const _NoHaptics()),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    theme: HabiterTheme.light(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
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
