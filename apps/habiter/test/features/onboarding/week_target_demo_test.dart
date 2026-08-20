import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/onboarding/application/onboarding_state.dart';
import 'package:habiter/features/onboarding/presentation/components/week_target_demo.dart';
import 'package:habiter/features/onboarding/presentation/models/schedule_education_model.dart';
import 'package:habiter/models/habit.dart';

void main() {
  testWidgets('counts different consecutive days once and allows undo', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(_app(_weeklyModel(), onChanged: changes.add));

    await tester.tap(_day(1));
    await tester.tap(_day(2));
    await tester.tap(_day(3));
    await tester.pump();

    expect(find.text('3 / 3'), findsOneWidget);
    expect(changes, <int>[1, 2, 3]);
    expect(
      tester.getSemantics(_day(3)).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    expect(
      tester.getSemantics(_day(4)).flagsCollection.isEnabled,
      ui.Tristate.isFalse,
    );

    await tester.tap(_day(2));
    await tester.pump();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(changes.last, 2);
  });

  testWidgets('fixed schedule keeps non-scheduled days neutral and disabled', (
    tester,
  ) async {
    final model = _ready(HabitFrequency.custom, customDays: const <int>[2, 4]);
    await tester.pumpWidget(_app(model, german: true));

    expect(tester.getSemantics(_day(1)).label, contains('Montag'));
    expect(
      tester.getSemantics(_day(1)).flagsCollection.isEnabled,
      ui.Tristate.isFalse,
    );
    expect(
      tester.getSemantics(_day(2)).flagsCollection.isEnabled,
      ui.Tristate.isTrue,
    );
    await tester.tap(_day(1), warnIfMissed: false);
    await tester.pump();
    expect(find.text('0 / 2'), findsOneWidget);
  });

  testWidgets('keyboard activation and numeric progress semantics work', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_weeklyModel()));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('week-demo-progress')))
          .label,
      '1 of 3 days selected',
    );
  });

  testWidgets('fits 320 dp with 200 percent text and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        _weeklyModel(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.tap(_day(1));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_day(1)), const Size(52, 52));
    final animated = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(
      animated.every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
  });
}

Finder _day(int weekday) =>
    find.byKey(ValueKey<String>('week-demo-day-$weekday'));

ScheduleEducationModel _weeklyModel() =>
    _ready(HabitFrequency.weekly, targetCount: 3);

ScheduleEducationModel _ready(
  HabitFrequency frequency, {
  int targetCount = 1,
  List<int> customDays = const <int>[],
}) {
  final result = ScheduleEducationMapper.fromDraft(
    OnboardingHabitDraft(
      name: 'Read',
      category: 'Learning',
      icon: '📚',
      color: '#7B61A8',
      frequency: frequency,
      targetCount: targetCount,
      customDays: customDays,
    ),
  );
  return (result as ScheduleEducationReady).model;
}

Widget _app(
  ScheduleEducationModel model, {
  ValueChanged<int>? onChanged,
  bool german = false,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) {
  const english = <int, String>{
    1: 'Mo',
    2: 'Tu',
    3: 'We',
    4: 'Th',
    5: 'Fr',
    6: 'Sa',
    7: 'Su',
  };
  const germanLabels = <int, String>{
    1: 'Mo',
    2: 'Di',
    3: 'Mi',
    4: 'Do',
    5: 'Fr',
    6: 'Sa',
    7: 'So',
  };
  const germanNames = <int, String>{
    1: 'Montag',
    2: 'Dienstag',
    3: 'Mittwoch',
    4: 'Donnerstag',
    5: 'Freitag',
    6: 'Samstag',
    7: 'Sonntag',
  };
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: textScaler,
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: WeekTargetDemo(
            model: model,
            weekLabel: german ? 'DIESE WOCHE' : 'THIS WEEK',
            weekdayLabels: german ? germanLabels : english,
            progressLabelBuilder: (completed, target) => '$completed / $target',
            progressSemanticsBuilder: (completed, target) => german
                ? '$completed von $target Tagen ausgewählt'
                : '$completed of $target days selected',
            weekdaySemanticsBuilder: (weekday, selected, enabled) {
              final name = german
                  ? germanNames[weekday]!
                  : const <int, String>{
                      1: 'Monday',
                      2: 'Tuesday',
                      3: 'Wednesday',
                      4: 'Thursday',
                      5: 'Friday',
                      6: 'Saturday',
                      7: 'Sunday',
                    }[weekday]!;
              return '$name, ${selected ? 'selected' : 'not selected'}';
            },
            onProgressChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}
