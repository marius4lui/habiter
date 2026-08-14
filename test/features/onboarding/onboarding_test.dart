import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/presentation/onboarding_empty_state.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

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
      expect(
        OnboardingController.stateFor(provider.habits),
        OnboardingState.welcome,
      );
      provider.dispose();
    },
  );

  test('migrated users skip welcome deterministically across restarts', () {
    final habits = <Object>[Object()];
    expect(OnboardingController.stateFor(habits), OnboardingState.active);
    expect(OnboardingController.stateFor(habits), OnboardingState.active);
  });

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
          ? 'Starte dein Momentum'
          : 'Start your momentum';
      expect(find.text(expected), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.textContaining('Drink Water'), findsNothing);
    });
  }
}
