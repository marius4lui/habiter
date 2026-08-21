import 'widget_configuration.dart';
import 'widget_configuration_options.dart';
import 'widget_habit_item.dart';

final class WidgetConfigurationProjection {
  const WidgetConfigurationProjection({
    required this.effective,
    required this.habits,
    required this.completedCount,
    required this.scheduledCount,
  });

  final EffectiveWidgetConfiguration effective;
  final List<WidgetHabitItem> habits;
  final int completedCount;
  final int scheduledCount;
}

WidgetConfigurationProjection projectWidgetConfiguration({
  required WidgetConfiguration configuration,
  required WidgetBreakpoint breakpoint,
  required Iterable<WidgetHabitItem> habits,
}) {
  var effective = configuration.effectiveFor(breakpoint);
  final selected = configuration.select(habits);
  var visible =
      configuration.showCompleted &&
          effective.shows(WidgetElement.completedHabits)
      ? selected
      : selected.where((habit) => !habit.isCompleted).toList(growable: false);
  final maximum = effective.maximumHabits ?? _defaultMaximum(breakpoint);
  if (visible.length > maximum) {
    visible = switch (effective.listSettings.overflowBehavior) {
      WidgetOverflowBehavior.truncate =>
        effective.maximumHabits == null && _defaultMaximum(breakpoint) == 1
            ? _focus(visible)
            : visible.take(maximum).toList(growable: false),
      WidgetOverflowBehavior.openOnly =>
        visible
            .where((habit) => !habit.isCompleted)
            .take(maximum)
            .toList(growable: false),
      WidgetOverflowBehavior.switchToFocus => _focus(visible),
    };
    if (effective.listSettings.overflowBehavior ==
        WidgetOverflowBehavior.switchToFocus) {
      effective = EffectiveWidgetConfiguration(
        contentMode: WidgetContentMode.focus,
        themeMode: effective.themeMode,
        accentMode: effective.accentMode,
        density: effective.density,
        progressMode: effective.progressMode,
        maximumHabits: effective.maximumHabits,
        outerPadding: effective.outerPadding,
        cornerRadius: effective.cornerRadius,
        textScale: effective.textScale,
        colorTokens: effective.colorTokens,
        surfaceTransparency: effective.surfaceTransparency,
        listSettings: effective.listSettings,
        progressSettings: effective.progressSettings,
        completionSettings: effective.completionSettings,
        geometry: effective.geometry,
        typography: effective.typography,
        stateStyles: effective.stateStyles,
        interactions: effective.interactions,
        hiddenElements: effective.hiddenElements,
      );
    }
  }
  if (effective.contentMode == WidgetContentMode.focus ||
      effective.contentMode == WidgetContentMode.minimal) {
    visible = _focus(visible);
  }
  return WidgetConfigurationProjection(
    effective: effective,
    habits: visible,
    completedCount: selected.where((habit) => habit.isCompleted).length,
    scheduledCount: selected.length,
  );
}

List<WidgetHabitItem> _focus(List<WidgetHabitItem> habits) => <WidgetHabitItem>[
  ...habits.where((habit) => !habit.isCompleted).take(1),
  if (!habits.any((habit) => !habit.isCompleted)) ...habits.take(1),
];

int _defaultMaximum(WidgetBreakpoint breakpoint) => switch (breakpoint) {
  WidgetBreakpoint.compact ||
  WidgetBreakpoint.compactSquare ||
  WidgetBreakpoint.wide ||
  WidgetBreakpoint.mediumHero => 1,
  WidgetBreakpoint.large => 3,
  WidgetBreakpoint.extraLarge => 6,
};
