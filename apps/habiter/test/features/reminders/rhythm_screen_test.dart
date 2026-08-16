import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/reminders/domain/reminder_policy.dart';
import 'package:habiter/features/reminders/presentation/habit_reminder_plan_editor.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:habiter/screens/rhythm_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/in_memory_key_value_store.dart';
import '../../support/fakes/recording_notification_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('shows truthful local learning state and a persisted reason', (
    tester,
  ) async {
    final provider = await _providerWithSmartPlan();
    addTearDown(provider.dispose);

    await tester.pumpWidget(_app(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Rhythm'), findsOneWidget);
    expect(find.text('Still learning'), findsOneWidget);
    expect(find.text('Availability profile'), findsOneWidget);
    expect(find.textContaining('Category preset'), findsWidgets);

    final whyButton = find.text('Why this time?');
    await tester.ensureVisible(whyButton);
    await tester.pumpAndSettle();
    await tester.tap(whyButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unanswered or dismissed notifications are never treated as negative feedback.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rhythm and editor remain usable at 320px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await _providerWithSmartPlan();
    addTearDown(provider.dispose);

    await tester.pumpWidget(_app(provider: provider, textScale: 2));
    await tester.pumpAndSettle();

    expect(find.text('Rhythm'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final habit = provider.habits.single;
    await tester.pumpWidget(
      _app(
        provider: provider,
        textScale: 2,
        home: HabitReminderPlanEditor(
          habit: habit,
          policy: provider.reminderPolicies[habit.id]!,
          onSave: provider.updateReminderPolicy,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Reminder plan'), findsOneWidget);
    expect(find.text('Smart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<HabitProvider> _providerWithSmartPlan() async {
  final store = InMemoryKeyValueStore();
  final provider = HabitProvider(
    repository: KeyValueHabitRepository(store),
    actionStore: store,
    notificationGateway: RecordingNotificationGateway(),
  );
  await provider.load();
  final id = await provider.addHabit(
    name: 'Walk',
    category: 'Health',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    color: '#467B68',
    icon: '🚶',
  );
  await provider.updateReminderPreferences(
    provider.reminderPreferences.copyWith(
      enabled: true,
      existingUserIntroductionSeen: true,
    ),
  );
  await provider.updateReminderPolicy(
    HabitReminderPolicy.smart(
      habitId: id,
      now: DateTime.now(),
      intensity: ReminderIntensity.persistent,
    ),
  );
  return provider;
}

Widget _app({
  required HabitProvider provider,
  Widget home = const RhythmScreen(),
  double textScale = 1,
}) => ChangeNotifierProvider<HabitProvider>.value(
  value: provider,
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
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  ),
);
