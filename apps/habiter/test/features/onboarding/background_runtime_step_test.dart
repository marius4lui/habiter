import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/steps/background_runtime_step.dart';
import 'package:habiter/features/runtime/domain/background_runtime_gateway.dart';
import 'package:habiter/features/runtime/domain/runtime_diagnostics.dart';
import 'package:habiter/features/runtime/domain/runtime_feature_state.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('reconciles runtime and refreshes battery status on resume', (
    tester,
  ) async {
    final controller = await _controllerAtBackgroundStep();
    addTearDown(controller.dispose);
    final gateway = _RuntimeGateway(
      features: const RuntimeFeatureState(
        remindersEnabled: false,
        appBlockEnabled: true,
      ),
      batteryOptimized: true,
    );

    await tester.pumpWidget(_app(controller, gateway));
    await tester.pumpAndSettle();

    expect(
      find.text('Keep Habiter active\nin the background.'),
      findsOneWidget,
    );
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Review Android settings'), findsOneWidget);
    expect(gateway.features.remindersEnabled, isTrue);
    expect(gateway.features.appBlockEnabled, isTrue);

    await tester.tap(find.byKey(const Key('background-open-battery-settings')));
    await tester.pump();
    expect(gateway.settingsOpens, 1);

    gateway.batteryOptimized = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Unrestricted'), findsOneWidget);
    expect(
      find.byKey(const Key('background-open-battery-settings')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('background-runtime-continue')));
    await tester.pumpAndSettle();
    expect(controller.state.currentStep, OnboardingStep.widgetIntro);
  });
}

Future<OnboardingController> _controllerAtBackgroundStep() async {
  final controller = OnboardingController(
    repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
    ids: FakeIdGenerator(const <String>['habit-1']),
    clock: FakeClock(DateTime.utc(2026, 8, 21)),
  );
  await controller.initialize(hasExistingHabits: false);
  await controller.start();
  await controller.selectIntent(OnboardingIntent.health);
  final draft = OnboardingHabitDraft(
    name: 'Walk',
    category: 'Health',
    icon: 'W',
    color: '#467B68',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    reminderEnabled: true,
  );
  await controller.selectHabit(draft);
  await controller.configureRhythm(draft);
  await controller.confirmRhythmUnderstanding();
  await controller.confirmReminderModel();
  await controller.configureReminder(draft);
  await controller.markHabitReady(backgroundSetupRequired: true);
  return controller;
}

Widget _app(
  OnboardingController controller,
  BackgroundRuntimeGateway gateway,
) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: BackgroundRuntimeStep(controller: controller, gateway: gateway),
);

final class _RuntimeGateway implements BackgroundRuntimeGateway {
  _RuntimeGateway({required this.features, required this.batteryOptimized});

  RuntimeFeatureState features;
  bool batteryOptimized;
  int settingsOpens = 0;

  @override
  bool get isSupported => true;

  @override
  Future<BackgroundRuntimeResult<RuntimeDiagnostics>> diagnostics() async =>
      BackgroundRuntimeSuccess<RuntimeDiagnostics>(
        RuntimeDiagnostics(features: features),
      );

  @override
  Future<BackgroundRuntimeResult<void>> invalidateReminders() async =>
      const BackgroundRuntimeSuccess<void>(null);

  @override
  Future<BackgroundRuntimeResult<void>> openBatterySettings() async {
    settingsOpens++;
    return const BackgroundRuntimeSuccess<void>(null);
  }

  @override
  Future<BackgroundRuntimeResult<void>> reconcile({
    required RuntimeFeatureState features,
    required String reason,
  }) async {
    this.features = features;
    return const BackgroundRuntimeSuccess<void>(null);
  }

  @override
  Future<BackgroundRuntimeResult<BackgroundRuntimeSnapshot>> snapshot() async =>
      BackgroundRuntimeSuccess<BackgroundRuntimeSnapshot>(
        BackgroundRuntimeSnapshot(
          features: features,
          notificationsGranted: true,
          batteryOptimized: batteryOptimized,
        ),
      );
}
