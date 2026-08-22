import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/habiter_theme.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/steps/reminder_step.dart';
import 'package:habiter/features/reminders/domain/calibration_session.dart';
import 'package:habiter/features/reminders/domain/reminder_policy.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';
import '../../support/fakes/recording_notification_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets(
    'explains Smart before permission and creates the prescribed defaults',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var permissionRequests = 0;
      final store = InMemoryKeyValueStore();
      final clock = FakeClock(DateTime(2026, 8, 17, 10));
      final provider = HabitProvider(
        repository: KeyValueHabitRepository(store),
        actionStore: store,
        notificationGateway: RecordingNotificationGateway(),
        clock: clock,
        ids: FakeIdGenerator(const <String>['calibration-1']),
        requestReminderPermission: () async {
          permissionRequests++;
          return true;
        },
      );
      await provider.load();
      addTearDown(provider.dispose);
      final controller = await _controllerAtReminder(clock);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(provider: provider, controller: controller, textScale: 2),
      );
      await tester.pumpAndSettle();

      expect(permissionRequests, 0);
      final smartChoice = find.text('Use Smart reminders');
      await tester.ensureVisible(smartChoice);
      await tester.pumpAndSettle();
      await tester.tap(smartChoice);
      await tester.pumpAndSettle();

      expect(find.text('Seven-day calibration'), findsOneWidget);
      expect(find.text('Only on this device'), findsOneWidget);
      expect(find.text('You stay in control'), findsOneWidget);
      expect(permissionRequests, 0);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Continue'));
      for (
        var attempt = 0;
        attempt < 30 &&
            controller.state.currentStep != OnboardingStep.backgroundRuntime;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(permissionRequests, 1);
      expect(controller.state.currentStep, OnboardingStep.backgroundRuntime);
      expect(provider.habits, hasLength(1));
      expect(provider.habits.single.notificationEnabled, isTrue);
      expect(provider.habits.single.notificationTime, isNull);
      expect(provider.reminderPreferences.enabled, isTrue);
      expect(provider.reminderPreferences.globalDailyLimit, 8);
      expect(provider.reminderPreferences.globalMinimumSpacing.inMinutes, 90);
      expect(provider.reminderPreferences.existingUserIntroductionSeen, isTrue);
      expect(provider.calibrationSession?.status, CalibrationStatus.active);
      expect(provider.reminderPolicies.values.single.mode, ReminderMode.smart);
      expect(
        provider.reminderPolicies.values.single.intensity,
        ReminderIntensity.persistent,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional path creates one habit without requesting permission', (
    tester,
  ) async {
    var permissionRequests = 0;
    final store = InMemoryKeyValueStore();
    final clock = FakeClock(DateTime(2026, 8, 17, 10));
    final provider = HabitProvider(
      repository: KeyValueHabitRepository(store),
      actionStore: store,
      notificationGateway: RecordingNotificationGateway(),
      clock: clock,
      ids: FakeIdGenerator(const <String>['calibration-unused']),
      requestReminderPermission: () async {
        permissionRequests++;
        return true;
      },
    );
    await provider.load();
    addTearDown(provider.dispose);
    final controller = await _controllerAtReminder(clock);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(provider: provider, controller: controller));
    expect(find.text('Without a reminder'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    for (
      var attempt = 0;
      attempt < 30 &&
          controller.state.currentStep != OnboardingStep.widgetIntro;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(permissionRequests, 0);
    expect(provider.habits, hasLength(1));
    expect(provider.habits.single.notificationEnabled, isFalse);
    expect(provider.reminderPreferences.enabled, isFalse);
    expect(controller.state.firstHabitId, 'habit-1');
    expect(controller.state.currentStep, OnboardingStep.widgetIntro);
  });
}

Future<OnboardingController> _controllerAtReminder(FakeClock clock) async {
  final controller = OnboardingController(
    repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
    ids: FakeIdGenerator(const <String>['habit-1']),
    clock: clock,
  );
  await controller.initialize(hasExistingHabits: false);
  await controller.start();
  await controller.selectIntent(OnboardingIntent.health);
  final draft = OnboardingHabitDraft(
    name: 'Walk',
    category: 'Health',
    icon: '🚶',
    color: '#467B68',
    frequency: HabitFrequency.daily,
    targetCount: 1,
  );
  await controller.selectHabit(draft);
  await controller.configureRhythm(draft);
  await controller.confirmRhythmUnderstanding();
  await controller.confirmReminderModel();
  return controller;
}

Widget _app({
  required HabitProvider provider,
  required OnboardingController controller,
  double textScale = 1,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<HabitProvider>.value(value: provider),
    ChangeNotifierProvider<OnboardingController>.value(value: controller),
    Provider<HapticGateway>.value(
      value: const SystemHapticGateway(isWeb: true),
    ),
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
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: ReminderStep(controller: controller),
  ),
);
