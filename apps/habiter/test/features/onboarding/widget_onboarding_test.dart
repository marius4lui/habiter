import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_controller.dart';
import 'package:habiter/features/onboarding/application/onboarding_repository.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/onboarding_flow.dart';
import 'package:habiter/features/widgets/domain/widget_bridge.dart';
import 'package:habiter/features/widgets/domain/widget_snapshot.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/theme/app_theme.dart';
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

    expect(find.text('Dein Habit.\nDirekt im Blick.'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
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

  testWidgets('widget onboarding remains usable at 200 percent text', (
    tester,
  ) async {
    final controller = await _controllerAtWidgetIntro();
    await tester.pumpWidget(
      _app(controller, const _FakeWidgetBridge(), textScale: 2),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Widget hinzufügen'), findsOneWidget);
    expect(find.text('Später'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final state in const <(WidgetPinResult, String)>[
    (WidgetPinResult.declined, 'Kein Problem.'),
    (
      WidgetPinResult.unsupported,
      'Automatisches Anheften wird hier nicht unterstützt. Manuell klappt es trotzdem.',
    ),
    (
      WidgetPinResult.failed,
      'Die Android-Anfrage hat nicht geklappt. Du kannst das Widget manuell hinzufügen.',
    ),
  ]) {
    testWidgets('${state.$1.name} pin state stays recoverable', (tester) async {
      final controller = await _controllerAtWidgetIntro();
      await controller.beginWidgetPin();
      await tester.pumpWidget(
        _app(controller, _FakeWidgetBridge(result: state.$1)),
      );

      await tester.tap(find.text('Widget hinzufügen'));
      await tester.pumpAndSettle();

      expect(find.text(state.$2), findsOneWidget);
      expect(controller.state.widgetPinAttempted, isTrue);
      expect(controller.state.currentStep, OnboardingStep.widgetPin);
      if (state.$1 == WidgetPinResult.unsupported ||
          state.$1 == WidgetPinResult.failed) {
        expect(find.text('Homescreen gedrückt halten'), findsOneWidget);
        expect(find.text('Widget platzieren'), findsOneWidget);
      }

      await tester.tap(find.text('Verstanden'));
      await tester.pump();
      expect(controller.state.currentStep, OnboardingStep.completed);
      expect(controller.state.widgetPinned, isFalse);
    });
  }

  testWidgets('widget intro light visual contract', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _controllerAtWidgetIntro();
    await tester.pumpWidget(_app(controller, const _FakeWidgetBridge()));
    await tester.pump(const Duration(milliseconds: 800));

    await expectLater(
      find.byType(OnboardingFlow),
      matchesGoldenFile('goldens/widget_intro_de_light.png'),
    );
  });

  testWidgets('widget intro dark visual contract', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await _controllerAtWidgetIntro();
    await tester.pumpWidget(
      _app(controller, const _FakeWidgetBridge(), themeMode: ThemeMode.dark),
    );
    await tester.pump(const Duration(milliseconds: 800));

    await expectLater(
      find.byType(OnboardingFlow),
      matchesGoldenFile('goldens/widget_intro_de_dark.png'),
    );
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

Widget _app(
  OnboardingController controller,
  WidgetBridge bridge, {
  double textScale = 1,
  ThemeMode themeMode = ThemeMode.light,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<OnboardingController>.value(value: controller),
    Provider<WidgetBridge>.value(value: bridge),
    Provider<HapticGateway>.value(
      value: const SystemHapticGateway(isWeb: true),
    ),
  ],
  child: MaterialApp(
    locale: const Locale('de'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    theme: buildAppTheme(),
    darkTheme: buildDarkTheme(),
    themeMode: themeMode,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const OnboardingFlow(),
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
