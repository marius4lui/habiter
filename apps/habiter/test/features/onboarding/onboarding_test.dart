import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/onboarding_empty_state.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/in_memory_key_value_store.dart';
import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'empty first start remains empty and notifications stay opt-in',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = HabitProvider(
        repository: KeyValueHabitRepository(InMemoryKeyValueStore()),
      );

      await provider.load();

      expect(provider.habits, isEmpty);
      expect(provider.preferences.notifications, isFalse);
      final controller = OnboardingController(
        repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
        ids: FakeIdGenerator(const <String>['first']),
        clock: FakeClock(DateTime.utc(2026, 8, 16)),
      );
      await controller.initialize(hasExistingHabits: false);
      expect(controller.state.currentStep, OnboardingStep.welcome);
      provider.dispose();
      controller.dispose();
    },
  );

  test(
    'migrated users skip welcome deterministically across restarts',
    () async {
      final store = InMemoryKeyValueStore();
      final repository = KeyValueOnboardingRepository(store);
      final first = OnboardingController(
        repository: repository,
        ids: FakeIdGenerator(const <String>[]),
        clock: FakeClock(DateTime.utc(2026, 8, 16)),
      );
      await first.initialize(hasExistingHabits: true);
      expect(first.state.currentStep, OnboardingStep.completed);

      final restarted = OnboardingController(
        repository: repository,
        ids: FakeIdGenerator(const <String>[]),
        clock: FakeClock(DateTime.utc(2026, 8, 17)),
      );
      await restarted.initialize(hasExistingHabits: true);
      expect(restarted.state.currentStep, OnboardingStep.completed);
      first.dispose();
      restarted.dispose();
    },
  );

  for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
    testWidgets('honest empty state is localized for ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OnboardingEmptyState(onCreateHabit: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final expected = locale.languageCode == 'de'
          ? 'Starte klein.'
          : 'Start small.';
      expect(find.text(expected), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.textContaining('Drink Water'), findsNothing);
    });
  }
}
