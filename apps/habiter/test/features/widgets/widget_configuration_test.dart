import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/widgets/domain/widget_configuration.dart';
import 'package:habiter/features/widgets/domain/widget_configuration_options.dart';
import 'package:habiter/features/widgets/domain/widget_configuration_projection.dart';
import 'package:habiter/features/widgets/domain/widget_habit_item.dart';

void main() {
  const habits = <WidgetHabitItem>[
    WidgetHabitItem(
      id: 'water',
      name: 'Water',
      icon: '💧',
      isCompleted: true,
      scheduleLabel: 'Daily',
    ),
    WidgetHabitItem(
      id: 'read',
      name: 'Read',
      icon: '📚',
      isCompleted: false,
      scheduleLabel: 'Daily',
    ),
    WidgetHabitItem(
      id: 'train',
      name: 'Train',
      icon: '🏋️',
      isCompleted: false,
      scheduleLabel: '3× per week',
    ),
  ];

  test('missing configuration preserves the legacy widget defaults', () {
    final configuration = WidgetConfiguration.fromJsonOrDefaults(
      null,
      widgetId: 17,
    );

    expect(configuration.widgetId, 17);
    expect(configuration.habitFilter, WidgetHabitFilter.allToday);
    expect(configuration.contentMode, WidgetContentMode.auto);
    expect(configuration.themeMode, WidgetThemeMode.system);
    expect(configuration.progressMode, WidgetProgressMode.automatic);
    expect(configuration.showProgress, isTrue);
    expect(configuration.showCompleted, isTrue);
    expect(configuration.oneTapCompletion, isTrue);
    expect(configuration.project(habits), habits);
  });

  test('configuration roundtrips independently for each widget id', () {
    final first = WidgetConfiguration(
      widgetId: 17,
      displayName: 'Training',
      habitFilter: WidgetHabitFilter.selected,
      selectedHabitIds: const <String>['train'],
      contentMode: WidgetContentMode.focus,
      themeMode: WidgetThemeMode.custom,
      colorTokens: const WidgetColorTokens(primary: '#3366FF'),
      breakpointOverrides: const <WidgetBreakpoint, WidgetBreakpointOverride>{
        WidgetBreakpoint.compact: WidgetBreakpointOverride(
          contentMode: WidgetContentMode.minimal,
          maximumHabits: 1,
        ),
      },
    );
    final second = WidgetConfiguration.defaults(widgetId: 18);

    final restored = WidgetConfiguration.fromJson(first.toJson(), widgetId: 17);

    expect(restored.displayName, 'Training');
    expect(restored.project(habits).single.id, 'train');
    expect(
      restored.effectiveFor(WidgetBreakpoint.compact).contentMode,
      WidgetContentMode.minimal,
    );
    expect(second.project(habits), habits);
    expect(
      () => WidgetConfiguration.fromJson(first.toJson(), widgetId: 18),
      throwsFormatException,
    );
  });

  test('legacy schema migrates known fields and invalid data falls back', () {
    final migrated = WidgetConfiguration.fromJsonOrDefaults(
      '{"schemaVersion":0,"widgetId":17,"contentMode":"minimal",'
      '"showProgress":false,"textScale":9}',
      widgetId: 17,
    );
    final corrupted = WidgetConfiguration.fromJsonOrDefaults(
      '{not json',
      widgetId: 17,
    );
    final future = WidgetConfiguration.fromJsonOrDefaults(
      '{"schemaVersion":99,"widgetId":17,"contentMode":"minimal"}',
      widgetId: 17,
    );

    expect(migrated.schemaVersion, WidgetConfiguration.currentSchemaVersion);
    expect(migrated.contentMode, WidgetContentMode.minimal);
    expect(migrated.showProgress, isFalse);
    expect(migrated.textScale, 1);
    expect(corrupted.contentMode, WidgetContentMode.auto);
    expect(future.contentMode, WidgetContentMode.auto);
  });

  test('selection ignores deleted and not-today ids while sorting safely', () {
    final selected = WidgetConfiguration(
      widgetId: 17,
      habitFilter: WidgetHabitFilter.selected,
      selectedHabitIds: const <String>['deleted', 'train', 'not-today'],
    );
    final custom = WidgetConfiguration(
      widgetId: 18,
      sortMode: WidgetSortMode.custom,
      customHabitOrder: const <String>['train', 'missing', 'water'],
    );

    expect(selected.project(habits).map((item) => item.id), <String>['train']);
    expect(custom.project(habits).map((item) => item.id), <String>[
      'train',
      'water',
      'read',
    ]);
  });

  test('breakpoint override layers over global accessibility bounds', () {
    final configuration = WidgetConfiguration(
      widgetId: 17,
      progressMode: WidgetProgressMode.segments,
      outerPadding: 12,
      cornerRadius: 24,
      textScale: 1.1,
      hiddenElements: const <WidgetElement>{WidgetElement.scheduleLabel},
      breakpointOverrides: const <WidgetBreakpoint, WidgetBreakpointOverride>{
        WidgetBreakpoint.wide: WidgetBreakpointOverride(
          progressMode: WidgetProgressMode.counter,
          outerPadding: 4,
          textScale: 1.4,
          hiddenElements: <WidgetElement>{WidgetElement.habitIcon},
        ),
      },
    );

    final effective = configuration.effectiveFor(WidgetBreakpoint.wide);

    expect(effective.progressMode, WidgetProgressMode.counter);
    expect(effective.outerPadding, 4);
    expect(effective.cornerRadius, 24);
    expect(effective.textScale, 1.4);
    expect(effective.shows(WidgetElement.scheduleLabel), isFalse);
    expect(effective.shows(WidgetElement.habitIcon), isFalse);
  });

  test('preset baselines stay compact and accept explicit overrides', () {
    final baseline = WidgetConfiguration.fromJson(
      '{"schemaVersion":1,"widgetId":17,"preset":"minimal"}',
      widgetId: 17,
    );
    final overridden = WidgetConfiguration.fromJson(
      '{"schemaVersion":1,"widgetId":17,"preset":"focus",'
      '"showProgress":true,"maximumHabits":2}',
      widgetId: 17,
    );

    expect(baseline.preset, WidgetPreset.minimal);
    expect(baseline.contentMode, WidgetContentMode.minimal);
    expect(baseline.showProgress, isFalse);
    expect(baseline.hiddenElements, contains(WidgetElement.todayHeader));
    expect(overridden.contentMode, WidgetContentMode.focus);
    expect(overridden.showProgress, isTrue);
    expect(overridden.maximumHabits, 2);
  });

  test('full cracked options roundtrip and resolve per breakpoint', () {
    final configuration = WidgetConfiguration(
      widgetId: 17,
      preset: WidgetPreset.dashboard,
      accentMode: WidgetAccentMode.custom,
      density: WidgetDensity.compact,
      surfaceTransparency: .2,
      listSettings: const WidgetListSettings(
        completedPlacement: WidgetCompletedPlacement.end,
        pinnedHabitIds: <String>['train'],
        overflowBehavior: WidgetOverflowBehavior.switchToFocus,
      ),
      progressSettings: const WidgetProgressSettings(
        segmentHeight: 8,
        segmentGap: 2,
        maximumSegments: 12,
        completedStyle: WidgetProgressCompletedStyle.muted,
        remainingStyle: WidgetProgressRemainingStyle.outline,
      ),
      completionSettings: const WidgetCompletionSettings(
        buttonStyle: WidgetCompletionButtonStyle.wholeRow,
        showUndo: false,
        feedback: WidgetCompletionFeedback.detailed,
        focusNextHabit: true,
      ),
      geometry: const WidgetGeometry(
        habitRowRadius: 18,
        buttonRadius: 12,
        horizontalPadding: 16,
        verticalPadding: 10,
        rowGap: 5,
        sectionGap: 11,
      ),
      typography: const WidgetTypography(
        habitTitleSize: 20,
        secondaryTextSize: 12,
        counterSize: 16,
        fontWeight: WidgetFontWeight.bold,
      ),
      stateStyles: const WidgetStateStyles(
        justCompleted: WidgetJustCompletedStyle.nextHabit,
        allComplete: WidgetAllCompleteStyle.iconOnly,
        freeToday: WidgetFreeTodayStyle.minimal,
        noHabits: WidgetNoHabitsStyle.compact,
        missingStale: WidgetMissingStaleStyle.compact,
      ),
      interactions: const WidgetInteractionMap(
        background: WidgetBackgroundAction.nextHabit,
        habitRow: WidgetHabitRowAction.complete,
        completionControl: WidgetCompletionAction.openHabit,
      ),
      breakpointOverrides: const <WidgetBreakpoint, WidgetBreakpointOverride>{
        WidgetBreakpoint.extraLarge: WidgetBreakpointOverride(
          density: WidgetDensity.comfortable,
          surfaceTransparency: .3,
          geometry: WidgetGeometry(horizontalPadding: 24),
          typography: WidgetTypography(habitTitleSize: 24),
        ),
      },
    );

    final restored = WidgetConfiguration.fromJson(
      configuration.toJson(),
      widgetId: 17,
    );
    final effective = restored.effectiveFor(WidgetBreakpoint.extraLarge);

    expect(restored.listSettings.pinnedHabitIds, <String>['train']);
    expect(restored.progressSettings.maximumSegments, 12);
    expect(restored.completionSettings.showUndo, isFalse);
    expect(restored.stateStyles.allComplete, WidgetAllCompleteStyle.iconOnly);
    expect(restored.interactions.habitRow, WidgetHabitRowAction.complete);
    expect(effective.density, WidgetDensity.comfortable);
    expect(effective.surfaceTransparency, .3);
    expect(effective.geometry.horizontalPadding, 24);
    expect(effective.geometry.habitRowRadius, 18);
    expect(effective.typography.habitTitleSize, 24);
    expect(effective.typography.counterSize, 16);
  });

  test('pinned and completed ordering remains deterministic', () {
    final configuration = WidgetConfiguration(
      widgetId: 17,
      listSettings: const WidgetListSettings(
        pinnedHabitIds: <String>['train'],
        completedPlacement: WidgetCompletedPlacement.end,
      ),
    );

    expect(configuration.select(habits).map((item) => item.id), <String>[
      'train',
      'read',
      'water',
    ]);
  });

  test('one-tap off resolves the completion control to open habit', () {
    final configuration = WidgetConfiguration(
      widgetId: 17,
      oneTapCompletion: false,
    );

    expect(
      configuration
          .effectiveFor(WidgetBreakpoint.compact)
          .interactions
          .completionControl,
      WidgetCompletionAction.openHabit,
    );
  });

  test('shared preview projection resolves every breakpoint like native', () {
    final configuration = WidgetConfiguration(
      widgetId: 17,
      breakpointOverrides: const <WidgetBreakpoint, WidgetBreakpointOverride>{
        WidgetBreakpoint.large: WidgetBreakpointOverride(
          contentMode: WidgetContentMode.focus,
          hiddenElements: <WidgetElement>{WidgetElement.completedHabits},
        ),
      },
    );

    for (final breakpoint in WidgetBreakpoint.values) {
      final projection = projectWidgetConfiguration(
        configuration: configuration,
        breakpoint: breakpoint,
        habits: habits,
      );
      expect(projection.scheduledCount, 3);
      expect(projection.completedCount, 1);
      if (breakpoint == WidgetBreakpoint.large) {
        expect(projection.effective.contentMode, WidgetContentMode.focus);
        expect(projection.habits.map((habit) => habit.id), <String>['read']);
      }
    }
  });
}
