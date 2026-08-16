import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/presentation/onboarding_flow.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('intent selection puts relevant localized templates first', (
    tester,
  ) async {
    final controller = OnboardingController(
      repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
      ids: FakeIdGenerator(const <String>['habit-1']),
      clock: FakeClock(DateTime.utc(2026, 8, 16)),
    );
    await controller.initialize(hasExistingHabits: false);

    await tester.pumpWidget(
      MultiProvider(
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
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gewohnheiten, die sichtbar bleiben.'), findsOneWidget);

    await tester.tap(find.text('Loslegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lernen'));
    await tester.pumpAndSettle();

    expect(find.text('Lesen'), findsOneWidget);
    expect(find.text('Sprache lernen'), findsOneWidget);
    expect(find.text('Instrument üben'), findsOneWidget);
    expect(find.text('Eigenes Habit erstellen'), findsOneWidget);
  });
}
