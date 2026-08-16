import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/onboarding_flow.dart';
import 'package:habiter/features/widgets/domain/widget_bridge.dart';
import 'package:habiter/features/widgets/domain/widget_snapshot.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:provider/provider.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('widget intro keeps Later visible and persists deferral', (
    tester,
  ) async {
    final controller = await _controllerAtWidgetIntro();
    await tester.pumpWidget(_app(controller, const _FakeWidgetBridge()));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Habiter gehört auf deinen Homescreen.'), findsOneWidget);
    expect(find.text('Später'), findsOneWidget);

    await tester.tap(find.text('Später'));
    await tester.pump();

    expect(controller.state.currentStep, OnboardingStep.completed);
    expect(
      controller.state.widgetPromotionState,
      WidgetPromotionState.deferred,
    );
  });

  testWidgets('pin success is only stored after native callback result', (
    tester,
  ) async {
    final controller = await _controllerAtWidgetIntro();
    await controller.beginWidgetPin();
    await tester.pumpWidget(
      _app(controller, const _FakeWidgetBridge(result: WidgetPinResult.pinned)),
    );

    await tester.tap(find.text('Widget hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('Bereit.'), findsOneWidget);
    expect(controller.state.widgetPinned, isFalse);

    await tester.tap(find.text("Los geht's"));
    await tester.pump();
    expect(controller.state.widgetPinned, isTrue);
    expect(controller.state.currentStep, OnboardingStep.completed);
  });
}

Future<OnboardingController> _controllerAtWidgetIntro() async {
  final controller = OnboardingController(
    repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
    ids: FakeIdGenerator(const <String>['habit-1']),
    clock: FakeClock(DateTime.utc(2026, 8, 16)),
  );
  await controller.initialize(hasExistingHabits: false);
  await controller.start();
  await controller.selectIntent(OnboardingIntent.fitness);
  final draft = OnboardingHabitDraft(
    name: 'Training',
    category: 'Fitness',
    icon: '🏋️',
    color: '#C45B42',
    frequency: HabitFrequency.daily,
    targetCount: 1,
  );
  await controller.selectHabit(draft);
  await controller.configureRhythm(draft);
  await controller.configureReminder(draft);
  await controller.markHabitReady();
  await controller.showWidgetIntro();
  return controller;
}

Widget _app(OnboardingController controller, WidgetBridge bridge) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<OnboardingController>.value(value: controller),
        Provider<WidgetBridge>.value(value: bridge),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: OnboardingFlow(),
      ),
    );

final class _FakeWidgetBridge implements WidgetBridge {
  const _FakeWidgetBridge({this.result = WidgetPinResult.pinned});

  final WidgetPinResult result;

  @override
  Future<bool> hasInstalledWidgets() async => result == WidgetPinResult.pinned;

  @override
  Future<bool> isPinningSupported() async =>
      result != WidgetPinResult.unsupported;

  @override
  Future<void> publish(WidgetSnapshot snapshot) async {}

  @override
  Future<WidgetPinResult> requestPin() async => result;

  @override
  Future<void> updateAll() async {}
}
