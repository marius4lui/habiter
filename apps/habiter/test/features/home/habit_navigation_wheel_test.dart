import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/design_system/haptics.dart';
import 'package:habiter/features/home/application/habit_hub_model.dart';
import 'package:habiter/features/home/presentation/habit_navigation_wheel.dart';
import 'package:habiter/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('drag snaps once without opening and emits one haptic', (
    tester,
  ) async {
    final haptics = _RecordingHaptics();
    final selected = <HabitHubDestination>[];
    final opened = <HabitHubDestination>[];
    await tester.pumpWidget(
      _fixture(
        haptics: haptics,
        onSelectionChanged: selected.add,
        onOpen: opened.add,
      ),
    );

    await tester.drag(
      find.byKey(const Key('habit-navigation-wheel')),
      const Offset(-170, 0),
    );
    await tester.pumpAndSettle();

    expect(selected, <HabitHubDestination>[HabitHubDestination.createHabit]);
    expect(opened, isEmpty);
    expect(haptics.selections, 1);

    await tester.tap(find.byKey(const Key('hub-wheel-open')));
    expect(opened, <HabitHubDestination>[HabitHubDestination.createHabit]);
  });

  testWidgets('side card selects first and selected card opens on second tap', (
    tester,
  ) async {
    final opened = <HabitHubDestination>[];
    await tester.pumpWidget(_fixture(onOpen: opened.add));

    await tester.tap(
      find.byKey(const Key('hub-wheel-card-createHabit')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(opened, isEmpty);

    await tester.tap(
      find.byKey(const Key('hub-wheel-card-createHabit')),
      warnIfMissed: false,
    );
    expect(opened, <HabitHubDestination>[HabitHubDestination.createHabit]);
  });

  testWidgets('reduced motion snaps immediately and stays overflow free', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final selected = <HabitHubDestination>[];
    await tester.pumpWidget(
      _fixture(
        disableAnimations: true,
        textScale: 2,
        onSelectionChanged: selected.add,
      ),
    );

    await tester.drag(
      find.byKey(const Key('habit-navigation-wheel')),
      const Offset(-170, 0),
    );
    await tester.pump();

    expect(selected, <HabitHubDestination>[HabitHubDestination.createHabit]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wheel is cyclic in the opposite direction', (tester) async {
    final selected = <HabitHubDestination>[];
    await tester.pumpWidget(_fixture(onSelectionChanged: selected.add));

    await tester.drag(
      find.byKey(const Key('habit-navigation-wheel')),
      const Offset(170, 0),
    );
    await tester.pumpAndSettle();

    expect(selected, <HabitHubDestination>[HabitHubDestination.settings]);
  });

  testWidgets('arrow keys select and enter opens the settled destination', (
    tester,
  ) async {
    final selected = <HabitHubDestination>[];
    final opened = <HabitHubDestination>[];
    await tester.pumpWidget(
      _fixture(onSelectionChanged: selected.add, onOpen: opened.add),
    );

    await tester.tap(find.byKey(const Key('hub-wheel-card-today')));
    opened.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(selected, <HabitHubDestination>[HabitHubDestination.createHabit]);
    expect(opened, <HabitHubDestination>[HabitHubDestination.createHabit]);
  });

  testWidgets('wheel exposes selected position and opening semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_fixture());

    expect(find.bySemanticsLabel('Today, option 1 of 7'), findsWidgets);
    expect(find.bySemanticsLabel('Open Today'), findsOneWidget);
    semantics.dispose();
  });
}

Widget _fixture({
  HapticGateway? haptics,
  ValueChanged<HabitHubDestination>? onSelectionChanged,
  ValueChanged<HabitHubDestination>? onOpen,
  bool disableAnimations = false,
  double textScale = 1,
}) => Provider<HapticGateway>.value(
  value: haptics ?? _RecordingHaptics(),
  child: MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: HabitNavigationWheel(
          onSelectionChanged: onSelectionChanged,
          onOpen: onOpen ?? (_) {},
        ),
      ),
    ),
  ),
);

class _RecordingHaptics implements HapticGateway {
  int selections = 0;

  @override
  Future<void> selection() async => selections++;

  @override
  Future<void> success() async {}
}
