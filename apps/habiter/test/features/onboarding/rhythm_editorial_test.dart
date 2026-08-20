import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/steps/rhythm_step.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('flexible weekly target keeps canonical target semantics', (
    tester,
  ) async {
    final controller = await _controllerAtRhythm();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    await tester.tap(find.text('Mehrmals pro Woche'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('rhythm-target-5')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('rhythm-target-5')));
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();

    expect(controller.state.currentStep, OnboardingStep.rhythmExplainer);
    expect(controller.state.habitDraft?.frequency, HabitFrequency.weekly);
    expect(controller.state.habitDraft?.targetCount, 5);
    expect(controller.state.habitDraft?.customDays, isEmpty);
  });

  testWidgets('fixed weekdays require a selection at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _controllerAtRhythm();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller, textScale: 2));

    await tester.ensureVisible(find.text('Bestimmte Tage'));
    await tester.tap(find.text('Bestimmte Tage'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Weiter'))
          .onPressed,
      isNull,
    );

    for (final day in const <int>[1, 5]) {
      final choice = find.byKey(ValueKey<String>('rhythm-day-$day'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
    await tester.pump();

    expect(controller.state.currentStep, OnboardingStep.rhythmExplainer);
    expect(controller.state.habitDraft?.frequency, HabitFrequency.custom);
    expect(controller.state.habitDraft?.targetCount, 1);
    expect(controller.state.habitDraft?.customDays, <int>[1, 5]);
    expect(tester.takeException(), isNull);
  });
}

Future<OnboardingController> _controllerAtRhythm() async {
  final controller = OnboardingController(
    repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
    ids: FakeIdGenerator(const <String>['habit-1']),
    clock: FakeClock(DateTime.utc(2026, 8, 20)),
  );
  await controller.initialize(hasExistingHabits: false);
  await controller.start();
  await controller.selectIntent(OnboardingIntent.health);
  await controller.selectHabit(
    OnboardingHabitDraft(
      name: 'Walk',
      category: 'Health',
      icon: 'W',
      color: '#467B68',
      frequency: HabitFrequency.daily,
      targetCount: 1,
    ),
  );
  return controller;
}

Widget _app(OnboardingController controller, {double textScale = 1}) =>
    MultiProvider(
      providers: [
        Provider<HapticGateway>.value(
          value: const SystemHapticGateway(isWeb: true),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        theme: buildAppTheme(),
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
        home: RhythmStep(controller: controller),
      ),
    );
