import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/steps/first_habit_step.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  testWidgets('custom habit validates, focuses, and fits at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = OnboardingController(
      repository: KeyValueOnboardingRepository(InMemoryKeyValueStore()),
      ids: FakeIdGenerator(const <String>['habit-1']),
      clock: FakeClock(DateTime.utc(2026, 8, 20)),
    );
    addTearDown(controller.dispose);
    await controller.initialize(hasExistingHabits: false);
    await controller.start();
    await controller.selectIntent(OnboardingIntent.learning);

    await tester.pumpWidget(_app(controller));
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding-custom-habit-toggle')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding-custom-habit-toggle')),
    );
    await tester.pump();

    final field = find.byKey(const ValueKey<String>('custom-habit-name'));
    expect(field, findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(field, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Name ist erforderlich'), findsOneWidget);
    expect(controller.state.currentStep, OnboardingStep.firstHabit);

    await tester.enterText(field, 'Journal');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.currentStep, OnboardingStep.rhythm);
    expect(controller.state.habitDraft?.name, 'Journal');
    expect(controller.state.habitDraft?.templateId, isNull);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(OnboardingController controller) => MultiProvider(
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
      ).copyWith(textScaler: const TextScaler.linear(2)),
      child: child!,
    ),
    home: FirstHabitStep(controller: controller),
  ),
);
