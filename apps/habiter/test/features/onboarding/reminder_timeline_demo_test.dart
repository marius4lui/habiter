import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/presentation/components/reminder_timeline_demo.dart';

void main() {
  testWidgets('Done changes progress and removes occurrence reminder', (
    tester,
  ) async {
    var interactions = 0;
    await tester.pumpWidget(_app(onInteracted: () => interactions++));

    await tester.tap(find.byKey(const ValueKey('reminder-demo-done-action')));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-demo-card')), findsNothing);
    expect(find.text('Workout counted for today.'), findsOneWidget);
    expect(interactions, 1);

    await tester.tap(find.byKey(const ValueKey('reminder-demo-reset')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-demo-card')), findsOneWidget);
  });

  testWidgets('Later moves time by 30 minutes without changing progress', (
    tester,
  ) async {
    var interactions = 0;
    await tester.pumpWidget(_app(onInteracted: () => interactions++));

    await tester.tap(find.byKey(const ValueKey('reminder-demo-later-action')));
    await tester.pump();

    expect(find.text('16:45'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-demo-card')), findsOneWidget);
    expect(find.text('Progress stays 1 / 3.'), findsOneWidget);
    expect(interactions, 1);

    await tester.tap(find.byKey(const ValueKey('reminder-demo-later-action')));
    await tester.pump();
    expect(find.text('17:15'), findsOneWidget);
    expect(interactions, 1);
  });

  testWidgets('actions are keyboard operable with precise semantics', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('reminder-demo-progress')))
          .label,
      '2 of 3 completed days',
    );
  });

  testWidgets('supports dark theme, 320 dp, large text and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        dark: true,
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    final later = find.byKey(const ValueKey('reminder-demo-later-action'));
    await tester.ensureVisible(later);
    await tester.tap(later);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('16:45'), findsOneWidget);
    expect(
      tester
          .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
          .every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
  });
}

Widget _app({
  VoidCallback? onInteracted,
  bool dark = false,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) => MaterialApp(
  theme: dark ? ThemeData.dark() : ThemeData.light(),
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: textScaler,
      disableAnimations: disableAnimations,
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        child: ReminderTimelineDemo(
          habitName: 'Workout',
          habitIcon: '🏋️',
          scheduleLabel: '3× per week',
          initialCompleted: 1,
          target: 3,
          initialReminderTime: const TimeOfDay(hour: 16, minute: 15),
          progressLabelBuilder: (completed, target) => '$completed / $target',
          progressSemanticsBuilder: (completed, target) =>
              '$completed of $target completed days',
          timeLabelBuilder: (time) =>
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          reminderQuestion: 'Does now work for you?',
          doneLabel: 'Done',
          laterLabel: 'Later',
          resetLabel: 'Reset demo',
          doneExplanation: 'Workout counted for today.',
          laterExplanation: 'Progress stays 1 / 3.',
          onInteracted: onInteracted,
        ),
      ),
    ),
  ),
);
