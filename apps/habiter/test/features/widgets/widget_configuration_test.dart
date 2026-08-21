import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/widgets/domain/widget_configuration.dart';
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
}
