import 'package:flutter/material.dart';

import '../../../core/design_system/components.dart';
import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../../../models/habit.dart';
import '../domain/widget_configuration.dart';
import '../domain/widget_configuration_options.dart';

class WidgetAdvancedEditor extends StatelessWidget {
  const WidgetAdvancedEditor({
    super.key,
    required this.configuration,
    required this.habits,
    required this.onChanged,
  });

  final WidgetConfiguration configuration;
  final List<Habit> habits;
  final ValueChanged<WidgetConfiguration> onChanged;

  void _setElement(WidgetElement element, bool visible) {
    final hidden = Set<WidgetElement>.from(configuration.hiddenElements);
    visible ? hidden.remove(element) : hidden.add(element);
    onChanged(configuration.copyWith(hiddenElements: hidden));
  }

  void _setOverride(
    WidgetBreakpoint breakpoint,
    WidgetBreakpointOverride? value,
  ) {
    final overrides = Map<WidgetBreakpoint, WidgetBreakpointOverride>.from(
      configuration.breakpointOverrides,
    );
    value == null
        ? overrides.remove(breakpoint)
        : overrides[breakpoint] = value;
    onChanged(configuration.copyWith(breakpointOverrides: overrides));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HabiterSpace.md),
    child: HabiterSurface(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('widget-advanced'),
        initiallyExpanded: false,
        leading: const Icon(Icons.tune_rounded),
        title: Text(context.l10n.widgetAdvancedTitle),
        subtitle: Text(context.l10n.widgetAdvancedBody),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: <Widget>[
          _Group(
            groupKey: const Key('widget-advanced-breakpoints'),
            title: context.l10n.widgetAdvancedBreakpoints,
            children: WidgetBreakpoint.values
                .map(
                  (breakpoint) => _BreakpointEditor(
                    breakpoint: breakpoint,
                    breakpointOverride:
                        configuration.breakpointOverrides[breakpoint],
                    global: configuration,
                    onChanged: (value) => _setOverride(breakpoint, value),
                  ),
                )
                .toList(growable: false),
          ),
          _Group(
            title: context.l10n.widgetAdvancedVisibleElements,
            children: WidgetElement.values
                .map(
                  (element) => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_elementLabel(context, element)),
                    value: !configuration.hiddenElements.contains(element),
                    onChanged: (value) => _setElement(element, value),
                  ),
                )
                .toList(growable: false),
          ),
          _Group(
            title: context.l10n.widgetAdvancedHabitList,
            children: <Widget>[
              _SliderField(
                label: context.l10n.widgetMaximumHabits,
                value: (configuration.maximumHabits ?? 3).toDouble(),
                minimum: 1,
                maximum: 12,
                divisions: 11,
                onChanged: (value) => onChanged(
                  configuration.copyWith(maximumHabits: value.round()),
                ),
              ),
              _EnumField<WidgetCompletedPlacement>(
                label: context.l10n.widgetCompletedPlacement,
                value: configuration.listSettings.completedPlacement,
                values: WidgetCompletedPlacement.values,
                labelFor: (value) => value == WidgetCompletedPlacement.end
                    ? context.l10n.widgetCompletedAtEnd
                    : context.l10n.widgetCompletedAsHabiter,
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    listSettings: configuration.listSettings.copyWith(
                      completedPlacement: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              _EnumField<WidgetOverflowBehavior>(
                label: context.l10n.widgetOverflow,
                value: configuration.listSettings.overflowBehavior,
                values: WidgetOverflowBehavior.values,
                labelFor: (value) => switch (value) {
                  WidgetOverflowBehavior.truncate =>
                    context.l10n.widgetOverflowTruncate,
                  WidgetOverflowBehavior.openOnly =>
                    context.l10n.widgetOverflowOpenOnly,
                  WidgetOverflowBehavior.switchToFocus =>
                    context.l10n.widgetOverflowFocus,
                },
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    listSettings: configuration.listSettings.copyWith(
                      overflowBehavior: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              Text(context.l10n.widgetPinnedHabits),
              ...habits
                  .where((habit) => habit.isActive)
                  .map(
                    (habit) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Text(habit.icon),
                      title: Text(habit.name),
                      value: configuration.listSettings.pinnedHabitIds.contains(
                        habit.id,
                      ),
                      onChanged: (selected) {
                        final ids = Set<String>.from(
                          configuration.listSettings.pinnedHabitIds,
                        );
                        selected == true
                            ? ids.add(habit.id)
                            : ids.remove(habit.id);
                        onChanged(
                          configuration.copyWith(
                            listSettings: configuration.listSettings.copyWith(
                              pinnedHabitIds: ids,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ],
          ),
          _Group(
            title: context.l10n.widgetAdvancedProgress,
            children: <Widget>[
              _EnumField<WidgetProgressMode>(
                label: context.l10n.widgetProgressMode,
                value: configuration.progressMode,
                values: WidgetProgressMode.values,
                labelFor: (value) => _progressLabel(context, value),
                onChanged: (value) =>
                    onChanged(configuration.copyWith(progressMode: value)),
              ),
              _SliderField(
                label: context.l10n.widgetSegmentHeight,
                value: configuration.progressSettings.segmentHeight ?? 5,
                minimum: 2,
                maximum: 12,
                divisions: 10,
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    progressSettings: configuration.progressSettings.copyWith(
                      segmentHeight: value,
                    ),
                  ),
                ),
              ),
              _SliderField(
                label: context.l10n.widgetSegmentGap,
                value: configuration.progressSettings.segmentGap ?? 4,
                minimum: 0,
                maximum: 12,
                divisions: 12,
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    progressSettings: configuration.progressSettings.copyWith(
                      segmentGap: value,
                    ),
                  ),
                ),
              ),
              _SliderField(
                label: context.l10n.widgetMaximumSegments,
                value: (configuration.progressSettings.maximumSegments ?? 8)
                    .toDouble(),
                minimum: 1,
                maximum: 24,
                divisions: 23,
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    progressSettings: configuration.progressSettings.copyWith(
                      maximumSegments: value.round(),
                    ),
                  ),
                ),
              ),
              _EnumField<WidgetProgressCompletedStyle>(
                label: context.l10n.widgetCompletedSegments,
                value: configuration.progressSettings.completedStyle,
                values: WidgetProgressCompletedStyle.values,
                labelFor: (value) => _completedSegmentLabel(context, value),
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    progressSettings: configuration.progressSettings.copyWith(
                      completedStyle: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              _EnumField<WidgetProgressRemainingStyle>(
                label: context.l10n.widgetRemainingSegments,
                value: configuration.progressSettings.remainingStyle,
                values: WidgetProgressRemainingStyle.values,
                labelFor: (value) => _remainingSegmentLabel(context, value),
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    progressSettings: configuration.progressSettings.copyWith(
                      remainingStyle: value,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _Group(
            title: context.l10n.widgetAdvancedCompletion,
            children: <Widget>[
              _EnumField<WidgetCompletionButtonStyle>(
                label: context.l10n.widgetCompletionButtonStyle,
                value: configuration.completionSettings.buttonStyle,
                values: WidgetCompletionButtonStyle.values,
                labelFor: (value) => _buttonStyleLabel(context, value),
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    completionSettings: configuration.completionSettings
                        .copyWith(buttonStyle: value),
                  ),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.widgetFocusNextHabit),
                value: configuration.completionSettings.focusNextHabit,
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    completionSettings: configuration.completionSettings
                        .copyWith(focusNextHabit: value),
                  ),
                ),
              ),
              _EnumField<WidgetCompletionFeedback>(
                label: context.l10n.widgetCompletionFeedbackLevel,
                value: configuration.completionSettings.feedback,
                values: WidgetCompletionFeedback.values,
                labelFor: (value) => switch (value) {
                  WidgetCompletionFeedback.minimal =>
                    context.l10n.widgetFeedbackMinimal,
                  WidgetCompletionFeedback.normal =>
                    context.l10n.widgetFeedbackNormal,
                  WidgetCompletionFeedback.detailed =>
                    context.l10n.widgetFeedbackDetailed,
                },
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    completionSettings: configuration.completionSettings
                        .copyWith(feedback: value),
                  ),
                ),
              ),
            ],
          ),
          _Group(
            title: context.l10n.widgetAdvancedThemeTokens,
            children: <Widget>[
              _EnumField<WidgetThemeMode>(
                label: context.l10n.widgetThemeTokenMode,
                value: configuration.themeMode,
                values: WidgetThemeMode.values,
                labelFor: (value) => switch (value) {
                  WidgetThemeMode.system => context.l10n.themeSystem,
                  WidgetThemeMode.light => context.l10n.themeLight,
                  WidgetThemeMode.dark => context.l10n.themeDark,
                  WidgetThemeMode.custom => context.l10n.widgetAccentCustom,
                },
                onChanged: (value) =>
                    onChanged(configuration.copyWith(themeMode: value)),
              ),
              const SizedBox(height: HabiterSpace.md),
              ..._colorFields(context),
              _SliderField(
                label: context.l10n.widgetSurfaceTransparency,
                value: configuration.surfaceTransparency,
                minimum: 0,
                maximum: .4,
                divisions: 8,
                fraction: true,
                onChanged: (value) => onChanged(
                  configuration.copyWith(surfaceTransparency: value),
                ),
              ),
            ],
          ),
          _Group(
            title: context.l10n.widgetAdvancedGeometry,
            children: <Widget>[
              _SliderField(
                label: context.l10n.widgetCornerRadius,
                value: configuration.cornerRadius ?? 24,
                minimum: 0,
                maximum: 40,
                divisions: 20,
                onChanged: (value) =>
                    onChanged(configuration.copyWith(cornerRadius: value)),
              ),
              _SliderField(
                label: context.l10n.widgetOuterPadding,
                value: configuration.outerPadding ?? 18,
                minimum: 0,
                maximum: 40,
                divisions: 20,
                onChanged: (value) =>
                    onChanged(configuration.copyWith(outerPadding: value)),
              ),
              ..._geometryFields(context),
            ],
          ),
          _Group(
            title: context.l10n.widgetAdvancedTypography,
            children: <Widget>[
              _SliderField(
                label: context.l10n.widgetTextScale,
                value: configuration.textScale,
                minimum: .8,
                maximum: 1.4,
                divisions: 6,
                fraction: true,
                onChanged: (value) =>
                    onChanged(configuration.copyWith(textScale: value)),
              ),
              ..._typographyFields(context),
              _EnumField<WidgetFontWeight>(
                label: context.l10n.widgetFontWeight,
                value: configuration.typography.fontWeight,
                values: WidgetFontWeight.values,
                labelFor: (value) => switch (value) {
                  WidgetFontWeight.system => context.l10n.widgetFontSystem,
                  WidgetFontWeight.regular => context.l10n.widgetFontRegular,
                  WidgetFontWeight.medium => context.l10n.widgetFontMedium,
                  WidgetFontWeight.bold => context.l10n.widgetFontBold,
                },
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    typography: configuration.typography.copyWith(
                      fontWeight: value,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _Group(
            title: context.l10n.widgetAdvancedStates,
            children: <Widget>[
              _EnumField<WidgetJustCompletedStyle>(
                label: context.l10n.widgetStateJustCompleted,
                value: configuration.stateStyles.justCompleted,
                values: WidgetJustCompletedStyle.values,
                labelFor: (value) => _justCompletedLabel(context, value),
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    stateStyles: configuration.stateStyles.copyWith(
                      justCompleted: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              _EnumField<WidgetAllCompleteStyle>(
                label: context.l10n.widgetStateAllComplete,
                value: configuration.stateStyles.allComplete,
                values: WidgetAllCompleteStyle.values,
                labelFor: (value) => _allCompleteLabel(context, value),
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    stateStyles: configuration.stateStyles.copyWith(
                      allComplete: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              _EnumField<WidgetFreeTodayStyle>(
                label: context.l10n.widgetStateFreeToday,
                value: configuration.stateStyles.freeToday,
                values: WidgetFreeTodayStyle.values,
                labelFor: (value) => _freeTodayLabel(context, value),
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    stateStyles: configuration.stateStyles.copyWith(
                      freeToday: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              _EnumField<WidgetNoHabitsStyle>(
                label: context.l10n.widgetStateNoHabits,
                value: configuration.stateStyles.noHabits,
                values: WidgetNoHabitsStyle.values,
                labelFor: (value) => value == WidgetNoHabitsStyle.compact
                    ? context.l10n.widgetStyleCompact
                    : context.l10n.widgetStyleDefault,
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    stateStyles: configuration.stateStyles.copyWith(
                      noHabits: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              _EnumField<WidgetMissingStaleStyle>(
                label: context.l10n.widgetStateMissingStale,
                value: configuration.stateStyles.missingStale,
                values: WidgetMissingStaleStyle.values,
                labelFor: (value) => value == WidgetMissingStaleStyle.compact
                    ? context.l10n.widgetStyleCompact
                    : context.l10n.widgetStyleSyncMessage,
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    stateStyles: configuration.stateStyles.copyWith(
                      missingStale: value,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _Group(
            title: context.l10n.widgetAdvancedInteractions,
            children: <Widget>[
              _EnumField<WidgetBackgroundAction>(
                label: context.l10n.widgetInteractionBackground,
                value: configuration.interactions.background,
                values: WidgetBackgroundAction.values,
                labelFor: (value) => _backgroundLabel(context, value),
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    interactions: configuration.interactions.copyWith(
                      background: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              _EnumField<WidgetHabitRowAction>(
                label: context.l10n.widgetInteractionHabitRow,
                value: configuration.interactions.habitRow,
                values: WidgetHabitRowAction.values,
                labelFor: (value) => switch (value) {
                  WidgetHabitRowAction.openHabit =>
                    context.l10n.widgetActionOpenHabit,
                  WidgetHabitRowAction.complete =>
                    context.l10n.widgetActionComplete,
                  WidgetHabitRowAction.none => context.l10n.widgetActionNone,
                },
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    interactions: configuration.interactions.copyWith(
                      habitRow: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              _EnumField<WidgetCompletionAction>(
                label: context.l10n.widgetInteractionCompletion,
                value: configuration.interactions.completionControl,
                values: WidgetCompletionAction.values,
                labelFor: (value) => value == WidgetCompletionAction.complete
                    ? context.l10n.widgetActionComplete
                    : context.l10n.widgetActionOpenHabit,
                onChanged: (value) => onChanged(
                  configuration.copyWith(
                    interactions: configuration.interactions.copyWith(
                      completionControl: value,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  List<Widget> _colorFields(BuildContext context) {
    final tokens = configuration.colorTokens;
    return <Widget>[
      _ColorField(
        label: context.l10n.widgetColorSurface,
        value: tokens.surface,
        onChanged: (value) => onChanged(
          configuration.copyWith(
            colorTokens: tokens.copyWith(
              surface: value,
              clearSurface: value == null,
            ),
          ),
        ),
      ),
      _ColorField(
        label: context.l10n.widgetColorSurfaceAccent,
        value: tokens.surfaceAccent,
        onChanged: (value) => onChanged(
          configuration.copyWith(
            colorTokens: tokens.copyWith(
              surfaceAccent: value,
              clearSurfaceAccent: value == null,
            ),
          ),
        ),
      ),
      _ColorField(
        label: context.l10n.widgetColorPrimary,
        value: tokens.primary,
        onChanged: (value) => onChanged(
          configuration.copyWith(
            colorTokens: tokens.copyWith(
              primary: value,
              clearPrimary: value == null,
            ),
          ),
        ),
      ),
      _ColorField(
        label: context.l10n.widgetColorText,
        value: tokens.text,
        onChanged: (value) => onChanged(
          configuration.copyWith(
            colorTokens: tokens.copyWith(text: value, clearText: value == null),
          ),
        ),
      ),
      _ColorField(
        label: context.l10n.widgetColorMutedText,
        value: tokens.mutedText,
        onChanged: (value) => onChanged(
          configuration.copyWith(
            colorTokens: tokens.copyWith(
              mutedText: value,
              clearMutedText: value == null,
            ),
          ),
        ),
      ),
      _ColorField(
        label: context.l10n.widgetColorSuccess,
        value: tokens.success,
        onChanged: (value) => onChanged(
          configuration.copyWith(
            colorTokens: tokens.copyWith(
              success: value,
              clearSuccess: value == null,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _geometryFields(BuildContext context) => <Widget>[
    _geometrySlider(
      context.l10n.widgetHabitRowRadius,
      configuration.geometry.habitRowRadius ?? 14,
      (value) => WidgetGeometry(
        habitRowRadius: value,
        buttonRadius: configuration.geometry.buttonRadius,
        horizontalPadding: configuration.geometry.horizontalPadding,
        verticalPadding: configuration.geometry.verticalPadding,
        rowGap: configuration.geometry.rowGap,
        sectionGap: configuration.geometry.sectionGap,
      ),
    ),
    _geometrySlider(
      context.l10n.widgetButtonRadius,
      configuration.geometry.buttonRadius ?? 14,
      (value) => WidgetGeometry(
        habitRowRadius: configuration.geometry.habitRowRadius,
        buttonRadius: value,
        horizontalPadding: configuration.geometry.horizontalPadding,
        verticalPadding: configuration.geometry.verticalPadding,
        rowGap: configuration.geometry.rowGap,
        sectionGap: configuration.geometry.sectionGap,
      ),
    ),
    _geometrySlider(
      context.l10n.widgetHorizontalPadding,
      configuration.geometry.horizontalPadding ?? 12,
      (value) => WidgetGeometry(
        habitRowRadius: configuration.geometry.habitRowRadius,
        buttonRadius: configuration.geometry.buttonRadius,
        horizontalPadding: value,
        verticalPadding: configuration.geometry.verticalPadding,
        rowGap: configuration.geometry.rowGap,
        sectionGap: configuration.geometry.sectionGap,
      ),
    ),
    _geometrySlider(
      context.l10n.widgetVerticalPadding,
      configuration.geometry.verticalPadding ?? 9,
      (value) => WidgetGeometry(
        habitRowRadius: configuration.geometry.habitRowRadius,
        buttonRadius: configuration.geometry.buttonRadius,
        horizontalPadding: configuration.geometry.horizontalPadding,
        verticalPadding: value,
        rowGap: configuration.geometry.rowGap,
        sectionGap: configuration.geometry.sectionGap,
      ),
    ),
    _geometrySlider(
      context.l10n.widgetRowGap,
      configuration.geometry.rowGap ?? 7,
      (value) => WidgetGeometry(
        habitRowRadius: configuration.geometry.habitRowRadius,
        buttonRadius: configuration.geometry.buttonRadius,
        horizontalPadding: configuration.geometry.horizontalPadding,
        verticalPadding: configuration.geometry.verticalPadding,
        rowGap: value,
        sectionGap: configuration.geometry.sectionGap,
      ),
      maximum: 24,
    ),
    _geometrySlider(
      context.l10n.widgetSectionGap,
      configuration.geometry.sectionGap ?? 12,
      (value) => WidgetGeometry(
        habitRowRadius: configuration.geometry.habitRowRadius,
        buttonRadius: configuration.geometry.buttonRadius,
        horizontalPadding: configuration.geometry.horizontalPadding,
        verticalPadding: configuration.geometry.verticalPadding,
        rowGap: configuration.geometry.rowGap,
        sectionGap: value,
      ),
      maximum: 32,
    ),
  ];

  Widget _geometrySlider(
    String label,
    double value,
    WidgetGeometry Function(double) geometry, {
    double maximum = 40,
  }) => _SliderField(
    label: label,
    value: value,
    minimum: 0,
    maximum: maximum,
    divisions: maximum.round(),
    onChanged: (value) =>
        onChanged(configuration.copyWith(geometry: geometry(value))),
  );

  List<Widget> _typographyFields(BuildContext context) => <Widget>[
    _typographySlider(
      context.l10n.widgetHabitTitleSize,
      configuration.typography.habitTitleSize ?? 15,
      10,
      28,
      (value) => WidgetTypography(
        habitTitleSize: value,
        secondaryTextSize: configuration.typography.secondaryTextSize,
        counterSize: configuration.typography.counterSize,
        fontWeight: configuration.typography.fontWeight,
      ),
    ),
    _typographySlider(
      context.l10n.widgetSecondaryTextSize,
      configuration.typography.secondaryTextSize ?? 12,
      9,
      22,
      (value) => WidgetTypography(
        habitTitleSize: configuration.typography.habitTitleSize,
        secondaryTextSize: value,
        counterSize: configuration.typography.counterSize,
        fontWeight: configuration.typography.fontWeight,
      ),
    ),
    _typographySlider(
      context.l10n.widgetCounterSize,
      configuration.typography.counterSize ?? 14,
      9,
      24,
      (value) => WidgetTypography(
        habitTitleSize: configuration.typography.habitTitleSize,
        secondaryTextSize: configuration.typography.secondaryTextSize,
        counterSize: value,
        fontWeight: configuration.typography.fontWeight,
      ),
    ),
  ];

  Widget _typographySlider(
    String label,
    double value,
    double minimum,
    double maximum,
    WidgetTypography Function(double) typography,
  ) => _SliderField(
    label: label,
    value: value,
    minimum: minimum,
    maximum: maximum,
    divisions: (maximum - minimum).round(),
    onChanged: (value) =>
        onChanged(configuration.copyWith(typography: typography(value))),
  );
}

class _BreakpointEditor extends StatelessWidget {
  const _BreakpointEditor({
    required this.breakpoint,
    required this.breakpointOverride,
    required this.global,
    required this.onChanged,
  });

  final WidgetBreakpoint breakpoint;
  final WidgetBreakpointOverride? breakpointOverride;
  final WidgetConfiguration global;
  final ValueChanged<WidgetBreakpointOverride?> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = breakpointOverride;
    return Padding(
      padding: const EdgeInsets.only(bottom: HabiterSpace.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(HabiterSpace.sm),
          child: Column(
            children: <Widget>[
              SwitchListTile.adaptive(
                key: Key('widget-override-${breakpoint.name}'),
                contentPadding: EdgeInsets.zero,
                title: Text(_breakpointLabel(context, breakpoint)),
                subtitle: Text(
                  value == null
                      ? context.l10n.widgetUseGlobalSettings
                      : context.l10n.widgetOverrideThisSize,
                ),
                value: value != null,
                onChanged: (enabled) => onChanged(
                  enabled
                      ? WidgetBreakpointOverride(
                          contentMode: global.contentMode,
                        )
                      : null,
                ),
              ),
              if (value != null) ...<Widget>[
                _EnumField<WidgetContentMode>(
                  label: context.l10n.widgetMode,
                  value: value.contentMode ?? global.contentMode,
                  values: WidgetContentMode.values,
                  labelFor: (mode) => _modeLabel(context, mode),
                  onChanged: (mode) =>
                      onChanged(value.copyWith(contentMode: mode)),
                ),
                const SizedBox(height: HabiterSpace.sm),
                _EnumField<WidgetProgressMode>(
                  label: context.l10n.widgetProgressMode,
                  value: value.progressMode ?? global.progressMode,
                  values: WidgetProgressMode.values,
                  labelFor: (mode) => _progressLabel(context, mode),
                  onChanged: (mode) =>
                      onChanged(value.copyWith(progressMode: mode)),
                ),
                _SliderField(
                  label: context.l10n.widgetMaximumHabits,
                  value: (value.maximumHabits ?? global.maximumHabits ?? 3)
                      .toDouble(),
                  minimum: 1,
                  maximum: 12,
                  divisions: 11,
                  onChanged: (number) =>
                      onChanged(value.copyWith(maximumHabits: number.round())),
                ),
                _SliderField(
                  label: context.l10n.widgetOuterPadding,
                  value: value.outerPadding ?? global.outerPadding ?? 18,
                  minimum: 0,
                  maximum: 40,
                  divisions: 20,
                  onChanged: (number) =>
                      onChanged(value.copyWith(outerPadding: number)),
                ),
                _SliderField(
                  label: context.l10n.widgetCornerRadius,
                  value: value.cornerRadius ?? global.cornerRadius ?? 24,
                  minimum: 0,
                  maximum: 40,
                  divisions: 20,
                  onChanged: (number) =>
                      onChanged(value.copyWith(cornerRadius: number)),
                ),
                _SliderField(
                  label: context.l10n.widgetTextScale,
                  value: value.textScale ?? global.textScale,
                  minimum: .8,
                  maximum: 1.4,
                  divisions: 6,
                  fraction: true,
                  onChanged: (number) =>
                      onChanged(value.copyWith(textScale: number)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({this.groupKey, required this.title, required this.children});

  final Key? groupKey;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: groupKey,
    title: Text(title),
    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
    childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
    children: children,
  );
}

class _EnumField<T> extends StatelessWidget {
  const _EnumField({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: values
        .map(
          (value) => DropdownMenuItem<T>(
            value: value,
            child: Text(labelFor(value), overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(growable: false),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.divisions,
    required this.onChanged,
    this.fraction = false,
  });

  final String label;
  final double value;
  final double minimum;
  final double maximum;
  final int divisions;
  final ValueChanged<double> onChanged;
  final bool fraction;

  @override
  Widget build(BuildContext context) {
    final bounded = value.clamp(minimum, maximum);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label · ${fraction ? bounded.toStringAsFixed(1) : bounded.round()}',
        ),
        Slider(
          value: bounded,
          min: minimum,
          max: maximum,
          divisions: divisions,
          label: fraction
              ? bounded.toStringAsFixed(1)
              : bounded.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ColorField extends StatefulWidget {
  const _ColorField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  State<_ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<_ColorField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _ColorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _controller.text != widget.value) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    const colors = <String>[
      '#17211C',
      '#285943',
      '#1D6B4B',
      '#8ED8B4',
      '#E3F2E8',
      '#FFFBF5',
      '#10231B',
      '#1B3A2C',
      '#6750A4',
      '#00639A',
      '#9C4146',
      '#765B00',
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.widgetChooseColor),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors
              .map(
                (hex) => Semantics(
                  button: true,
                  label: hex,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, hex),
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse('FF${hex.substring(1)}', radix: 16),
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (selected == null) return;
    _controller.text = selected;
    widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HabiterSpace.sm),
    child: TextField(
      controller: _controller,
      maxLength: 9,
      autocorrect: false,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: '#285943',
        prefixIcon: IconButton(
          tooltip: context.l10n.widgetChooseColor,
          onPressed: _pickColor,
          icon: const Icon(Icons.color_lens_outlined),
        ),
        suffixIcon: IconButton(
          tooltip: context.l10n.widgetResetToken,
          onPressed: () {
            _controller.clear();
            widget.onChanged(null);
          },
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ),
      onChanged: (source) {
        final normalized = source.trim().toUpperCase();
        if (RegExp(r'^#[0-9A-F]{6}([0-9A-F]{2})?$').hasMatch(normalized)) {
          widget.onChanged(normalized);
        }
      },
    ),
  );
}

String _modeLabel(BuildContext context, WidgetContentMode value) =>
    switch (value) {
      WidgetContentMode.auto => context.l10n.widgetModeAuto,
      WidgetContentMode.focus => context.l10n.widgetModeFocus,
      WidgetContentMode.list => context.l10n.widgetModeList,
      WidgetContentMode.minimal => context.l10n.widgetModeMinimal,
    };

String _progressLabel(BuildContext context, WidgetProgressMode value) =>
    switch (value) {
      WidgetProgressMode.automatic => context.l10n.widgetProgressAutomatic,
      WidgetProgressMode.hidden => context.l10n.widgetProgressHidden,
      WidgetProgressMode.segments => context.l10n.widgetProgressSegments,
      WidgetProgressMode.counter => context.l10n.widgetProgressCounter,
      WidgetProgressMode.both => context.l10n.widgetProgressBoth,
    };

String _breakpointLabel(BuildContext context, WidgetBreakpoint value) =>
    switch (value) {
      WidgetBreakpoint.compact => context.l10n.widgetBreakpointCompact,
      WidgetBreakpoint.compactSquare =>
        context.l10n.widgetBreakpointCompactSquare,
      WidgetBreakpoint.wide => context.l10n.widgetBreakpointWide,
      WidgetBreakpoint.mediumHero => context.l10n.widgetBreakpointMediumHero,
      WidgetBreakpoint.large => context.l10n.widgetBreakpointLarge,
      WidgetBreakpoint.extraLarge => context.l10n.widgetBreakpointExtraLarge,
    };

String _elementLabel(
  BuildContext context,
  WidgetElement value,
) => switch (value) {
  WidgetElement.habitIcon => context.l10n.widgetElementHabitIcon,
  WidgetElement.habitName => context.l10n.widgetElementHabitName,
  WidgetElement.scheduleLabel => context.l10n.widgetElementSchedule,
  WidgetElement.progressSegments => context.l10n.widgetElementSegments,
  WidgetElement.counter => context.l10n.widgetElementCounter,
  WidgetElement.todayHeader => context.l10n.widgetElementTodayHeader,
  WidgetElement.completionButton => context.l10n.widgetElementCompletionButton,
  WidgetElement.completedHabits => context.l10n.widgetElementCompletedHabits,
  WidgetElement.completionCheckmark => context.l10n.widgetElementCheckmark,
  WidgetElement.undoButton => context.l10n.widgetElementUndo,
  WidgetElement.emptyStateText => context.l10n.widgetElementEmptyText,
  WidgetElement.doneStateText => context.l10n.widgetElementDoneText,
};

String _completedSegmentLabel(
  BuildContext context,
  WidgetProgressCompletedStyle value,
) => switch (value) {
  WidgetProgressCompletedStyle.solid => context.l10n.widgetStyleSolid,
  WidgetProgressCompletedStyle.muted => context.l10n.widgetStyleMuted,
  WidgetProgressCompletedStyle.hidden => context.l10n.widgetProgressHidden,
};

String _remainingSegmentLabel(
  BuildContext context,
  WidgetProgressRemainingStyle value,
) => switch (value) {
  WidgetProgressRemainingStyle.track => context.l10n.widgetStyleTrack,
  WidgetProgressRemainingStyle.outline => context.l10n.widgetStyleOutline,
  WidgetProgressRemainingStyle.hidden => context.l10n.widgetProgressHidden,
};

String _buttonStyleLabel(
  BuildContext context,
  WidgetCompletionButtonStyle value,
) => switch (value) {
  WidgetCompletionButtonStyle.automatic => context.l10n.widgetStyleAutomatic,
  WidgetCompletionButtonStyle.checkOnly => context.l10n.widgetStyleCheckOnly,
  WidgetCompletionButtonStyle.textOnly => context.l10n.widgetStyleTextOnly,
  WidgetCompletionButtonStyle.checkAndText =>
    context.l10n.widgetStyleCheckAndText,
  WidgetCompletionButtonStyle.wholeRow => context.l10n.widgetStyleWholeRow,
};

String _justCompletedLabel(
  BuildContext context,
  WidgetJustCompletedStyle value,
) => switch (value) {
  WidgetJustCompletedStyle.full => context.l10n.widgetStyleFull,
  WidgetJustCompletedStyle.compact => context.l10n.widgetStyleCompact,
  WidgetJustCompletedStyle.checkOnly => context.l10n.widgetStyleCheckOnly,
  WidgetJustCompletedStyle.nextHabit => context.l10n.widgetStyleNextHabit,
};

String _allCompleteLabel(BuildContext context, WidgetAllCompleteStyle value) =>
    switch (value) {
      WidgetAllCompleteStyle.card => context.l10n.widgetStyleCard,
      WidgetAllCompleteStyle.message => context.l10n.widgetStyleMessage,
      WidgetAllCompleteStyle.minimal => context.l10n.widgetModeMinimal,
      WidgetAllCompleteStyle.iconOnly => context.l10n.widgetStyleIconOnly,
    };

String _freeTodayLabel(BuildContext context, WidgetFreeTodayStyle value) =>
    switch (value) {
      WidgetFreeTodayStyle.textAndIcon => context.l10n.widgetStyleTextAndIcon,
      WidgetFreeTodayStyle.textOnly => context.l10n.widgetStyleTextOnly,
      WidgetFreeTodayStyle.iconOnly => context.l10n.widgetStyleIconOnly,
      WidgetFreeTodayStyle.minimal => context.l10n.widgetModeMinimal,
    };

String _backgroundLabel(BuildContext context, WidgetBackgroundAction value) =>
    switch (value) {
      WidgetBackgroundAction.today => context.l10n.widgetBackgroundToday,
      WidgetBackgroundAction.nextHabit => context.l10n.widgetBackgroundNext,
      WidgetBackgroundAction.app => context.l10n.widgetBackgroundApp,
    };
