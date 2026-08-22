enum WidgetPreset { defaults, minimal, focus, denseList, dashboard }

enum WidgetAccentMode { habiter, dynamicColor, custom }

enum WidgetDensity { compact, comfortable }

enum WidgetBackgroundAction { today, nextHabit, app }

enum WidgetHabitRowAction { openHabit, complete, none }

enum WidgetCompletionAction { complete, openHabit }

enum WidgetCompletionButtonStyle {
  automatic,
  checkOnly,
  textOnly,
  checkAndText,
  wholeRow,
}

enum WidgetCompletionFeedback { minimal, normal, detailed }

enum WidgetOverflowBehavior { truncate, openOnly, switchToFocus }

enum WidgetCompletedPlacement { asInHabiter, end }

enum WidgetProgressCompletedStyle { solid, muted, hidden }

enum WidgetProgressRemainingStyle { track, outline, hidden }

enum WidgetFontWeight { system, regular, medium, bold }

enum WidgetJustCompletedStyle { full, compact, checkOnly, nextHabit }

enum WidgetAllCompleteStyle { card, message, minimal, iconOnly }

enum WidgetFreeTodayStyle { textAndIcon, textOnly, iconOnly, minimal }

enum WidgetNoHabitsStyle { defaultState, compact }

enum WidgetMissingStaleStyle { syncMessage, compact }

final class WidgetListSettings {
  const WidgetListSettings({
    this.completedPlacement = WidgetCompletedPlacement.asInHabiter,
    this.pinnedHabitIds = const <String>[],
    this.overflowBehavior = WidgetOverflowBehavior.truncate,
  });

  factory WidgetListSettings.fromMap(Map<String, Object?> map) =>
      WidgetListSettings(
        completedPlacement: _enumOr(
          WidgetCompletedPlacement.values,
          map['completedPlacement'],
          WidgetCompletedPlacement.asInHabiter,
        ),
        pinnedHabitIds: _strings(map['pinnedHabitIds']),
        overflowBehavior: _enumOr(
          WidgetOverflowBehavior.values,
          map['overflowBehavior'],
          WidgetOverflowBehavior.truncate,
        ),
      );

  final WidgetCompletedPlacement completedPlacement;
  final List<String> pinnedHabitIds;
  final WidgetOverflowBehavior overflowBehavior;

  WidgetListSettings copyWith({
    WidgetCompletedPlacement? completedPlacement,
    Iterable<String>? pinnedHabitIds,
    WidgetOverflowBehavior? overflowBehavior,
  }) => WidgetListSettings(
    completedPlacement: completedPlacement ?? this.completedPlacement,
    pinnedHabitIds:
        pinnedHabitIds?.toList(growable: false) ?? this.pinnedHabitIds,
    overflowBehavior: overflowBehavior ?? this.overflowBehavior,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'completedPlacement': completedPlacement.name,
    'pinnedHabitIds': pinnedHabitIds,
    'overflowBehavior': overflowBehavior.name,
  };
}

final class WidgetProgressSettings {
  const WidgetProgressSettings({
    this.segmentHeight,
    this.segmentGap,
    this.maximumSegments,
    this.completedStyle = WidgetProgressCompletedStyle.solid,
    this.remainingStyle = WidgetProgressRemainingStyle.track,
  });

  factory WidgetProgressSettings.fromMap(Map<String, Object?> map) =>
      WidgetProgressSettings(
        segmentHeight: _boundedDouble(map['segmentHeight'], 2, 12),
        segmentGap: _boundedDouble(map['segmentGap'], 0, 12),
        maximumSegments: _boundedInt(map['maximumSegments'], 1, 24),
        completedStyle: _enumOr(
          WidgetProgressCompletedStyle.values,
          map['completedStyle'],
          WidgetProgressCompletedStyle.solid,
        ),
        remainingStyle: _enumOr(
          WidgetProgressRemainingStyle.values,
          map['remainingStyle'],
          WidgetProgressRemainingStyle.track,
        ),
      );

  final double? segmentHeight;
  final double? segmentGap;
  final int? maximumSegments;
  final WidgetProgressCompletedStyle completedStyle;
  final WidgetProgressRemainingStyle remainingStyle;

  WidgetProgressSettings copyWith({
    double? segmentHeight,
    bool clearSegmentHeight = false,
    double? segmentGap,
    bool clearSegmentGap = false,
    int? maximumSegments,
    bool clearMaximumSegments = false,
    WidgetProgressCompletedStyle? completedStyle,
    WidgetProgressRemainingStyle? remainingStyle,
  }) => WidgetProgressSettings(
    segmentHeight: clearSegmentHeight
        ? null
        : (segmentHeight ?? this.segmentHeight),
    segmentGap: clearSegmentGap ? null : (segmentGap ?? this.segmentGap),
    maximumSegments: clearMaximumSegments
        ? null
        : (maximumSegments ?? this.maximumSegments),
    completedStyle: completedStyle ?? this.completedStyle,
    remainingStyle: remainingStyle ?? this.remainingStyle,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    if (segmentHeight != null) 'segmentHeight': segmentHeight,
    if (segmentGap != null) 'segmentGap': segmentGap,
    if (maximumSegments != null) 'maximumSegments': maximumSegments,
    'completedStyle': completedStyle.name,
    'remainingStyle': remainingStyle.name,
  };
}

final class WidgetCompletionSettings {
  const WidgetCompletionSettings({
    this.buttonStyle = WidgetCompletionButtonStyle.automatic,
    this.showUndo = true,
    this.feedback = WidgetCompletionFeedback.normal,
    this.focusNextHabit = false,
  });

  factory WidgetCompletionSettings.fromMap(Map<String, Object?> map) =>
      WidgetCompletionSettings(
        buttonStyle: _enumOr(
          WidgetCompletionButtonStyle.values,
          map['buttonStyle'],
          WidgetCompletionButtonStyle.automatic,
        ),
        showUndo: map['showUndo'] as bool? ?? true,
        feedback: _enumOr(
          WidgetCompletionFeedback.values,
          map['feedback'],
          WidgetCompletionFeedback.normal,
        ),
        focusNextHabit: map['focusNextHabit'] as bool? ?? false,
      );

  final WidgetCompletionButtonStyle buttonStyle;
  final bool showUndo;
  final WidgetCompletionFeedback feedback;
  final bool focusNextHabit;

  WidgetCompletionSettings copyWith({
    WidgetCompletionButtonStyle? buttonStyle,
    bool? showUndo,
    WidgetCompletionFeedback? feedback,
    bool? focusNextHabit,
  }) => WidgetCompletionSettings(
    buttonStyle: buttonStyle ?? this.buttonStyle,
    showUndo: showUndo ?? this.showUndo,
    feedback: feedback ?? this.feedback,
    focusNextHabit: focusNextHabit ?? this.focusNextHabit,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'buttonStyle': buttonStyle.name,
    'showUndo': showUndo,
    'feedback': feedback.name,
    'focusNextHabit': focusNextHabit,
  };
}

final class WidgetGeometry {
  const WidgetGeometry({
    this.habitRowRadius,
    this.buttonRadius,
    this.horizontalPadding,
    this.verticalPadding,
    this.rowGap,
    this.sectionGap,
  });

  factory WidgetGeometry.fromMap(Map<String, Object?> map) => WidgetGeometry(
    habitRowRadius: _boundedDouble(map['habitRowRadius'], 0, 40),
    buttonRadius: _boundedDouble(map['buttonRadius'], 0, 40),
    horizontalPadding: _boundedDouble(map['horizontalPadding'], 0, 40),
    verticalPadding: _boundedDouble(map['verticalPadding'], 0, 40),
    rowGap: _boundedDouble(map['rowGap'], 0, 24),
    sectionGap: _boundedDouble(map['sectionGap'], 0, 32),
  );

  final double? habitRowRadius;
  final double? buttonRadius;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double? rowGap;
  final double? sectionGap;

  WidgetGeometry merge(WidgetGeometry? override) => WidgetGeometry(
    habitRowRadius: override?.habitRowRadius ?? habitRowRadius,
    buttonRadius: override?.buttonRadius ?? buttonRadius,
    horizontalPadding: override?.horizontalPadding ?? horizontalPadding,
    verticalPadding: override?.verticalPadding ?? verticalPadding,
    rowGap: override?.rowGap ?? rowGap,
    sectionGap: override?.sectionGap ?? sectionGap,
  );

  WidgetGeometry copyWith({
    double? habitRowRadius,
    double? buttonRadius,
    double? horizontalPadding,
    double? verticalPadding,
    double? rowGap,
    double? sectionGap,
  }) => WidgetGeometry(
    habitRowRadius: habitRowRadius ?? this.habitRowRadius,
    buttonRadius: buttonRadius ?? this.buttonRadius,
    horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    verticalPadding: verticalPadding ?? this.verticalPadding,
    rowGap: rowGap ?? this.rowGap,
    sectionGap: sectionGap ?? this.sectionGap,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    if (habitRowRadius != null) 'habitRowRadius': habitRowRadius,
    if (buttonRadius != null) 'buttonRadius': buttonRadius,
    if (horizontalPadding != null) 'horizontalPadding': horizontalPadding,
    if (verticalPadding != null) 'verticalPadding': verticalPadding,
    if (rowGap != null) 'rowGap': rowGap,
    if (sectionGap != null) 'sectionGap': sectionGap,
  };
}

final class WidgetTypography {
  const WidgetTypography({
    this.habitTitleSize,
    this.secondaryTextSize,
    this.counterSize,
    this.fontWeight = WidgetFontWeight.system,
  });

  factory WidgetTypography.fromMap(Map<String, Object?> map) =>
      WidgetTypography(
        habitTitleSize: _boundedDouble(map['habitTitleSize'], 10, 28),
        secondaryTextSize: _boundedDouble(map['secondaryTextSize'], 9, 22),
        counterSize: _boundedDouble(map['counterSize'], 9, 24),
        fontWeight: _enumOr(
          WidgetFontWeight.values,
          map['fontWeight'],
          WidgetFontWeight.system,
        ),
      );

  final double? habitTitleSize;
  final double? secondaryTextSize;
  final double? counterSize;
  final WidgetFontWeight fontWeight;

  WidgetTypography merge(WidgetTypography? override) => WidgetTypography(
    habitTitleSize: override?.habitTitleSize ?? habitTitleSize,
    secondaryTextSize: override?.secondaryTextSize ?? secondaryTextSize,
    counterSize: override?.counterSize ?? counterSize,
    fontWeight: override?.fontWeight ?? fontWeight,
  );

  WidgetTypography copyWith({
    double? habitTitleSize,
    double? secondaryTextSize,
    double? counterSize,
    WidgetFontWeight? fontWeight,
  }) => WidgetTypography(
    habitTitleSize: habitTitleSize ?? this.habitTitleSize,
    secondaryTextSize: secondaryTextSize ?? this.secondaryTextSize,
    counterSize: counterSize ?? this.counterSize,
    fontWeight: fontWeight ?? this.fontWeight,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    if (habitTitleSize != null) 'habitTitleSize': habitTitleSize,
    if (secondaryTextSize != null) 'secondaryTextSize': secondaryTextSize,
    if (counterSize != null) 'counterSize': counterSize,
    'fontWeight': fontWeight.name,
  };
}

final class WidgetStateStyles {
  const WidgetStateStyles({
    this.justCompleted = WidgetJustCompletedStyle.full,
    this.allComplete = WidgetAllCompleteStyle.card,
    this.freeToday = WidgetFreeTodayStyle.textAndIcon,
    this.noHabits = WidgetNoHabitsStyle.defaultState,
    this.missingStale = WidgetMissingStaleStyle.syncMessage,
  });

  factory WidgetStateStyles.fromMap(Map<String, Object?> map) =>
      WidgetStateStyles(
        justCompleted: _enumOr(
          WidgetJustCompletedStyle.values,
          map['justCompleted'],
          WidgetJustCompletedStyle.full,
        ),
        allComplete: _enumOr(
          WidgetAllCompleteStyle.values,
          map['allComplete'],
          WidgetAllCompleteStyle.card,
        ),
        freeToday: _enumOr(
          WidgetFreeTodayStyle.values,
          map['freeToday'],
          WidgetFreeTodayStyle.textAndIcon,
        ),
        noHabits: _enumOr(
          WidgetNoHabitsStyle.values,
          map['noHabits'],
          WidgetNoHabitsStyle.defaultState,
        ),
        missingStale: _enumOr(
          WidgetMissingStaleStyle.values,
          map['missingStale'],
          WidgetMissingStaleStyle.syncMessage,
        ),
      );

  final WidgetJustCompletedStyle justCompleted;
  final WidgetAllCompleteStyle allComplete;
  final WidgetFreeTodayStyle freeToday;
  final WidgetNoHabitsStyle noHabits;
  final WidgetMissingStaleStyle missingStale;

  WidgetStateStyles copyWith({
    WidgetJustCompletedStyle? justCompleted,
    WidgetAllCompleteStyle? allComplete,
    WidgetFreeTodayStyle? freeToday,
    WidgetNoHabitsStyle? noHabits,
    WidgetMissingStaleStyle? missingStale,
  }) => WidgetStateStyles(
    justCompleted: justCompleted ?? this.justCompleted,
    allComplete: allComplete ?? this.allComplete,
    freeToday: freeToday ?? this.freeToday,
    noHabits: noHabits ?? this.noHabits,
    missingStale: missingStale ?? this.missingStale,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'justCompleted': justCompleted.name,
    'allComplete': allComplete.name,
    'freeToday': freeToday.name,
    'noHabits': noHabits.name,
    'missingStale': missingStale.name,
  };
}

final class WidgetInteractionMap {
  const WidgetInteractionMap({
    this.background = WidgetBackgroundAction.today,
    this.habitRow = WidgetHabitRowAction.none,
    this.completionControl = WidgetCompletionAction.complete,
  });

  factory WidgetInteractionMap.fromMap(Map<String, Object?> map) =>
      WidgetInteractionMap(
        background: _enumOr(
          WidgetBackgroundAction.values,
          map['background'],
          WidgetBackgroundAction.today,
        ),
        habitRow: _enumOr(
          WidgetHabitRowAction.values,
          map['habitRow'],
          WidgetHabitRowAction.none,
        ),
        completionControl: _enumOr(
          WidgetCompletionAction.values,
          map['completionControl'],
          WidgetCompletionAction.complete,
        ),
      );

  final WidgetBackgroundAction background;
  final WidgetHabitRowAction habitRow;
  final WidgetCompletionAction completionControl;

  WidgetInteractionMap copyWith({
    WidgetBackgroundAction? background,
    WidgetHabitRowAction? habitRow,
    WidgetCompletionAction? completionControl,
  }) => WidgetInteractionMap(
    background: background ?? this.background,
    habitRow: habitRow ?? this.habitRow,
    completionControl: completionControl ?? this.completionControl,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'background': background.name,
    'habitRow': habitRow.name,
    'completionControl': completionControl.name,
  };
}

T _enumOr<T extends Enum>(List<T> values, Object? source, T fallback) {
  if (source is String) {
    for (final value in values) {
      if (value.name == source) return value;
    }
  }
  return fallback;
}

List<String> _strings(Object? source) => source is List
    ? source
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
    : const <String>[];

int? _boundedInt(Object? source, int minimum, int maximum) {
  if (source is! num) return null;
  final value = source.toInt();
  return value >= minimum && value <= maximum ? value : null;
}

double? _boundedDouble(Object? source, double minimum, double maximum) {
  if (source is! num) return null;
  final value = source.toDouble();
  return value.isFinite && value >= minimum && value <= maximum ? value : null;
}
