import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/steps/reminder_education_step.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/theme/app_theme.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('real draft and rhythm drive the interactive reminder story', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _controllerAtReminderEducation();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    expect(find.text('Lesen'), findsWidgets);
    expect(find.text('3× pro Woche'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Verstanden'))
          .onPressed,
      isNull,
    );

    final later = find.byKey(
      const ValueKey<String>('reminder-demo-later-action'),
    );
    await tester.ensureVisible(later);
    await tester.tap(later);
    await tester.pump();

    expect(find.text('16:45'), findsOneWidget);
    expect(controller.state.currentStep, OnboardingStep.reminderModel);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Verstanden'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Verstanden'));
    await tester.pump();

    expect(controller.state.currentStep, OnboardingStep.reminder);
    expect(tester.takeException(), isNull);
  });
}

Future<OnboardingController> _controllerAtReminderEducation() async {
  final controller = OnboardingController(
    repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
    ids: FakeIdGenerator(const <String>['habit-1']),
    clock: FakeClock(DateTime.utc(2026, 8, 20)),
  );
  await controller.initialize(hasExistingHabits: false);
  await controller.start();
  await controller.selectIntent(OnboardingIntent.learning);
  final draft = OnboardingHabitDraft(
    name: 'Lesen',
    category: 'Learning',
    icon: '📚',
    color: '#7B61A8',
    frequency: HabitFrequency.weekly,
    targetCount: 3,
  );
  await controller.selectHabit(draft);
  await controller.configureRhythm(draft);
  await controller.confirmRhythmUnderstanding();
  return controller;
}

Widget _app(OnboardingController controller) => MaterialApp(
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
    ).copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: ReminderEducationStep(controller: controller),
);
