import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/steps/reminder_education_step.dart';
import 'package:habiter/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/theme/app_theme.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('welcome story light visual contract at 412 dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _welcomeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        home: WelcomeStep(controller: controller),
      ),
    );

    await expectLater(
      find.byType(WelcomeStep),
      matchesGoldenFile('goldens/editorial_welcome_de_light_412.png'),
    );
  });

  testWidgets('reminder story dark visual contract at 412 dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _reminderController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        dark: true,
        home: ReminderEducationStep(controller: controller),
      ),
    );

    await expectLater(
      find.byType(ReminderEducationStep),
      matchesGoldenFile('goldens/editorial_reminder_en_dark_412.png'),
    );
  });
}

Future<OnboardingController> _welcomeController() async {
  final controller = _controller();
  await controller.initialize(hasExistingHabits: false);
  return controller;
}

Future<OnboardingController> _reminderController() async {
  final controller = _controller();
  await controller.initialize(hasExistingHabits: false);
  await controller.start();
  await controller.selectIntent(OnboardingIntent.learning);
  final draft = OnboardingHabitDraft(
    name: 'Read',
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

OnboardingController _controller() => OnboardingController(
  repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
  ids: FakeIdGenerator(const <String>['habit-1']),
  clock: FakeClock(DateTime.utc(2026, 8, 20)),
);

Widget _app({
  required Locale locale,
  required Widget home,
  bool dark = false,
}) => MaterialApp(
  locale: locale,
  theme: buildAppTheme(),
  darkTheme: buildDarkTheme(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);
