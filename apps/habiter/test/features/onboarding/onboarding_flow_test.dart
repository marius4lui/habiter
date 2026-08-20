import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/onboarding_flow.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:provider/provider.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('nested navigator handles system back before the app route', (
    tester,
  ) async {
    final controller = OnboardingController(
      repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
      ids: FakeIdGenerator(const <String>['habit-1']),
      clock: FakeClock(DateTime.utc(2026, 8, 16)),
    );
    addTearDown(controller.dispose);
    await controller.initialize(hasExistingHabits: false);
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Loslegen'));
    await tester.pumpAndSettle();
    expect(controller.state.currentStep, OnboardingStep.intent);
    expect(find.byType(Navigator), findsNWidgets(2));
    expect(find.byType(AnimatedSwitcher), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(controller.state.currentStep, OnboardingStep.welcome);
    expect(find.text('Kleine Schritte.\nEchte Veränderung.'), findsOneWidget);
  });

  testWidgets('resumed onboarding restores a poppable inner history', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    final repository = KeyValueOnboardingRepository(store);
    final first = OnboardingController(
      repository: repository,
      ids: FakeIdGenerator(const <String>['habit-1']),
      clock: FakeClock(DateTime.utc(2026, 8, 16)),
    );
    await first.initialize(hasExistingHabits: false);
    await first.start();
    await first.selectIntent(OnboardingIntent.learning);
    await first.selectHabit(
      OnboardingHabitDraft(
        name: 'Read',
        category: 'Learning',
        icon: '📚',
        color: '#7B61A8',
        frequency: HabitFrequency.daily,
        targetCount: 1,
      ),
    );
    first.dispose();

    final restarted = OnboardingController(
      repository: repository,
      ids: FakeIdGenerator(const <String>['unused']),
      clock: FakeClock(DateTime.utc(2026, 8, 17)),
    );
    addTearDown(restarted.dispose);
    await restarted.initialize(hasExistingHabits: false);
    await tester.pumpWidget(_app(restarted));
    await tester.pumpAndSettle();
    expect(restarted.state.currentStep, OnboardingStep.rhythm);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(restarted.state.currentStep, OnboardingStep.firstHabit);
    expect(find.text('Lesen'), findsOneWidget);
  });

  testWidgets('intent selection puts relevant localized templates first', (
    tester,
  ) async {
    final controller = OnboardingController(
      repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
      ids: FakeIdGenerator(const <String>['habit-1']),
      clock: FakeClock(DateTime.utc(2026, 8, 16)),
    );
    await controller.initialize(hasExistingHabits: false);

    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    expect(find.text('Kleine Schritte.\nEchte Veränderung.'), findsOneWidget);

    await tester.tap(find.text('Loslegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lernen'));
    await tester.pumpAndSettle();

    expect(find.text('Lesen'), findsOneWidget);
    expect(find.text('Sprache lernen'), findsOneWidget);
    expect(find.text('Instrument üben'), findsOneWidget);
    expect(find.text('Eigenes Habit erstellen'), findsOneWidget);
  });

  testWidgets('actual rhythm demo requires interaction before continuing', (
    tester,
  ) async {
    final controller = OnboardingController(
      repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
      ids: FakeIdGenerator(const <String>['habit-1']),
      clock: FakeClock(DateTime.utc(2026, 8, 16)),
    );
    addTearDown(controller.dispose);
    await controller.initialize(hasExistingHabits: false);
    await controller.start();
    await controller.selectIntent(OnboardingIntent.learning);
    await controller.selectHabit(
      OnboardingHabitDraft(
        name: 'Lesen',
        category: 'Learning',
        icon: '📚',
        color: '#7B61A8',
        frequency: HabitFrequency.weekly,
        targetCount: 3,
      ),
    );
    await controller.configureRhythm(controller.state.habitDraft!);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(
      find.text('3× pro Woche heißt: 3 verschiedene Tage.'),
      findsOneWidget,
    );
    expect(find.text('Drei Tage hintereinander? Völlig okay.'), findsNothing);
    final understand = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Verstanden'),
    );
    expect(understand.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('week-demo-day-1')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Verstanden'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Verstanden'));
    await tester.pumpAndSettle();

    expect(controller.state.currentStep, OnboardingStep.reminderModel);
  });
}

Widget _app(OnboardingController controller) => MultiProvider(
  providers: [
    ChangeNotifierProvider<OnboardingController>.value(value: controller),
    Provider<HapticGateway>.value(
      value: const SystemHapticGateway(isWeb: true),
    ),
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
