import 'dart:collection';
import 'dart:convert';

import 'widget_configuration_options.dart';
import 'widget_habit_item.dart';

enum WidgetHabitFilter { allToday, openOnly, selected }

enum WidgetSortMode { asInHabiter, openFirst, custom }

enum WidgetContentMode { auto, focus, list, minimal }

enum WidgetThemeMode { system, light, dark, custom }

enum WidgetProgressMode { automatic, hidden, segments, counter, both }

enum WidgetBreakpoint {
  compact,
  compactSquare,
  wide,
  mediumHero,
  large,
  extraLarge,
}

enum WidgetElement {
  habitIcon,
  habitName,
  scheduleLabel,
  progressSegments,
  counter,
  todayHeader,
  completionButton,
  completedHabits,
  completionCheckmark,
  undoButton,
  emptyStateText,
  doneStateText,
}

final class WidgetColorTokens {
  const WidgetColorTokens({
    this.surface,
    this.surfaceAccent,
    this.primary,
    this.text,
    this.mutedText,
    this.success,
  });

  factory WidgetColorTokens.fromMap(Map<String, Object?> map) =>
      WidgetColorTokens(
        surface: _color(map['surface']),
        surfaceAccent: _color(map['surfaceAccent']),
        primary: _color(map['primary']),
        text: _color(map['text']),
        mutedText: _color(map['mutedText']),
        success: _color(map['success']),
      );

  final String? surface;
  final String? surfaceAccent;
  final String? primary;
  final String? text;
  final String? mutedText;
  final String? success;

  bool get isEmpty =>
      surface == null &&
      surfaceAccent == null &&
      primary == null &&
      text == null &&
      mutedText == null &&
      success == null;

  Map<String, Object?> toMap() => <String, Object?>{
    if (surface != null) 'surface': surface,
    if (surfaceAccent != null) 'surfaceAccent': surfaceAccent,
    if (primary != null) 'primary': primary,
    if (text != null) 'text': text,
    if (mutedText != null) 'mutedText': mutedText,
    if (success != null) 'success': success,
  };

  static String? _color(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toUpperCase();
    return RegExp(r'^#[0-9A-F]{6}([0-9A-F]{2})?$').hasMatch(normalized)
        ? normalized
        : null;
  }
}

final class WidgetBreakpointOverride {
  const WidgetBreakpointOverride({
    this.contentMode,
    this.themeMode,
    this.accentMode,
    this.density,
    this.progressMode,
    this.maximumHabits,
    this.outerPadding,
    this.cornerRadius,
    this.textScale,
    this.colorTokens,
    this.surfaceTransparency,
    this.listSettings,
    this.progressSettings,
    this.completionSettings,
    this.geometry,
    this.typography,
    this.stateStyles,
    this.interactions,
    this.hiddenElements = const <WidgetElement>{},
  });

  factory WidgetBreakpointOverride.fromMap(
    Map<String, Object?> map,
  ) => WidgetBreakpointOverride(
    contentMode: _enumOrNull(WidgetContentMode.values, map['contentMode']),
    themeMode: _enumOrNull(WidgetThemeMode.values, map['themeMode']),
    accentMode: _enumOrNull(WidgetAccentMode.values, map['accentMode']),
    density: _enumOrNull(WidgetDensity.values, map['density']),
    progressMode: _enumOrNull(WidgetProgressMode.values, map['progressMode']),
    maximumHabits: _boundedInt(map['maximumHabits'], 1, 12),
    outerPadding: _boundedDouble(map['outerPadding'], 0, 40),
    cornerRadius: _boundedDouble(map['cornerRadius'], 0, 40),
    textScale: _boundedDouble(map['textScale'], 0.8, 1.4),
    colorTokens: map['colorTokens'] is Map
        ? WidgetColorTokens.fromMap(
            Map<String, Object?>.from(map['colorTokens']! as Map),
          )
        : null,
    surfaceTransparency: _boundedDouble(map['surfaceTransparency'], 0, 0.4),
    listSettings: _nested(map['listSettings'], WidgetListSettings.fromMap),
    progressSettings: _nested(
      map['progressSettings'],
      WidgetProgressSettings.fromMap,
    ),
    completionSettings: _nested(
      map['completionSettings'],
      WidgetCompletionSettings.fromMap,
    ),
    geometry: _nested(map['geometry'], WidgetGeometry.fromMap),
    typography: _nested(map['typography'], WidgetTypography.fromMap),
    stateStyles: _nested(map['stateStyles'], WidgetStateStyles.fromMap),
    interactions: _nested(map['interactions'], WidgetInteractionMap.fromMap),
    hiddenElements: _elements(map['hiddenElements']),
  );

  final WidgetContentMode? contentMode;
  final WidgetThemeMode? themeMode;
  final WidgetAccentMode? accentMode;
  final WidgetDensity? density;
  final WidgetProgressMode? progressMode;
  final int? maximumHabits;
  final double? outerPadding;
  final double? cornerRadius;
  final double? textScale;
  final WidgetColorTokens? colorTokens;
  final double? surfaceTransparency;
  final WidgetListSettings? listSettings;
  final WidgetProgressSettings? progressSettings;
  final WidgetCompletionSettings? completionSettings;
  final WidgetGeometry? geometry;
  final WidgetTypography? typography;
  final WidgetStateStyles? stateStyles;
  final WidgetInteractionMap? interactions;
  final Set<WidgetElement> hiddenElements;

  bool get isEmpty =>
      contentMode == null &&
      themeMode == null &&
      accentMode == null &&
      density == null &&
      progressMode == null &&
      maximumHabits == null &&
      outerPadding == null &&
      cornerRadius == null &&
      textScale == null &&
      colorTokens == null &&
      surfaceTransparency == null &&
      listSettings == null &&
      progressSettings == null &&
      completionSettings == null &&
      geometry == null &&
      typography == null &&
      stateStyles == null &&
      interactions == null &&
      hiddenElements.isEmpty;

  Map<String, Object?> toMap() => <String, Object?>{
    if (contentMode != null) 'contentMode': contentMode!.name,
    if (themeMode != null) 'themeMode': themeMode!.name,
    if (accentMode != null) 'accentMode': accentMode!.name,
    if (density != null) 'density': density!.name,
    if (progressMode != null) 'progressMode': progressMode!.name,
    if (maximumHabits != null) 'maximumHabits': maximumHabits,
    if (outerPadding != null) 'outerPadding': outerPadding,
    if (cornerRadius != null) 'cornerRadius': cornerRadius,
    if (textScale != null) 'textScale': textScale,
    if (colorTokens != null && !colorTokens!.isEmpty)
      'colorTokens': colorTokens!.toMap(),
    if (surfaceTransparency != null) 'surfaceTransparency': surfaceTransparency,
    if (listSettings != null) 'listSettings': listSettings!.toMap(),
    if (progressSettings != null) 'progressSettings': progressSettings!.toMap(),
    if (completionSettings != null)
      'completionSettings': completionSettings!.toMap(),
    if (geometry != null) 'geometry': geometry!.toMap(),
    if (typography != null) 'typography': typography!.toMap(),
    if (stateStyles != null) 'stateStyles': stateStyles!.toMap(),
    if (interactions != null) 'interactions': interactions!.toMap(),
    if (hiddenElements.isNotEmpty)
      'hiddenElements': hiddenElements.map((item) => item.name).toList(),
  };
}

final class EffectiveWidgetConfiguration {
  const EffectiveWidgetConfiguration({
    required this.contentMode,
    required this.themeMode,
    required this.accentMode,
    required this.density,
    required this.progressMode,
    required this.maximumHabits,
    required this.outerPadding,
    required this.cornerRadius,
    required this.textScale,
    required this.colorTokens,
    required this.surfaceTransparency,
    required this.listSettings,
    required this.progressSettings,
    required this.completionSettings,
    required this.geometry,
    required this.typography,
    required this.stateStyles,
    required this.interactions,
    required this.hiddenElements,
  });

  final WidgetContentMode contentMode;
  final WidgetThemeMode themeMode;
  final WidgetAccentMode accentMode;
  final WidgetDensity density;
  final WidgetProgressMode progressMode;
  final int? maximumHabits;
  final double? outerPadding;
  final double? cornerRadius;
  final double textScale;
  final WidgetColorTokens colorTokens;
  final double surfaceTransparency;
  final WidgetListSettings listSettings;
  final WidgetProgressSettings progressSettings;
  final WidgetCompletionSettings completionSettings;
  final WidgetGeometry geometry;
  final WidgetTypography typography;
  final WidgetStateStyles stateStyles;
  final WidgetInteractionMap interactions;
  final Set<WidgetElement> hiddenElements;

  bool shows(WidgetElement element) => !hiddenElements.contains(element);
}

final class WidgetConfiguration {
  WidgetConfiguration({
    this.schemaVersion = currentSchemaVersion,
    required this.widgetId,
    this.displayName,
    this.preset = WidgetPreset.defaults,
    this.habitFilter = WidgetHabitFilter.allToday,
    Iterable<String> selectedHabitIds = const <String>[],
    this.sortMode = WidgetSortMode.asInHabiter,
    Iterable<String> customHabitOrder = const <String>[],
    this.contentMode = WidgetContentMode.auto,
    this.themeMode = WidgetThemeMode.system,
    this.accentMode = WidgetAccentMode.habiter,
    this.density = WidgetDensity.comfortable,
    this.showProgress = true,
    this.showCompleted = true,
    this.oneTapCompletion = true,
    this.progressMode = WidgetProgressMode.automatic,
    this.maximumHabits,
    this.colorTokens = const WidgetColorTokens(),
    this.surfaceTransparency = 0,
    this.listSettings = const WidgetListSettings(),
    this.progressSettings = const WidgetProgressSettings(),
    this.completionSettings = const WidgetCompletionSettings(),
    this.outerPadding,
    this.cornerRadius,
    this.textScale = 1,
    this.geometry = const WidgetGeometry(),
    this.typography = const WidgetTypography(),
    this.stateStyles = const WidgetStateStyles(),
    this.interactions = const WidgetInteractionMap(),
    Iterable<WidgetElement> hiddenElements = const <WidgetElement>[],
    Map<WidgetBreakpoint, WidgetBreakpointOverride> breakpointOverrides =
        const <WidgetBreakpoint, WidgetBreakpointOverride>{},
  }) : selectedHabitIds = UnmodifiableListView<String>(
         LinkedHashSet<String>.from(selectedHabitIds),
       ),
       customHabitOrder = UnmodifiableListView<String>(
         LinkedHashSet<String>.from(customHabitOrder),
       ),
       hiddenElements = UnmodifiableSetView<WidgetElement>(
         Set<WidgetElement>.from(hiddenElements),
       ),
       breakpointOverrides = UnmodifiableMapView(
         Map<WidgetBreakpoint, WidgetBreakpointOverride>.from(
           breakpointOverrides,
         )..removeWhere((_, value) => value.isEmpty),
       );

  static const currentSchemaVersion = 1;

  factory WidgetConfiguration.defaults({required int widgetId}) =>
      WidgetConfiguration(widgetId: widgetId);

  factory WidgetConfiguration.forPreset({
    required int widgetId,
    required WidgetPreset preset,
    String? displayName,
  }) => switch (preset) {
    WidgetPreset.defaults => WidgetConfiguration(
      widgetId: widgetId,
      displayName: displayName,
    ),
    WidgetPreset.minimal => WidgetConfiguration(
      widgetId: widgetId,
      displayName: displayName,
      preset: preset,
      contentMode: WidgetContentMode.minimal,
      showProgress: false,
      showCompleted: false,
      density: WidgetDensity.compact,
      hiddenElements: const <WidgetElement>{
        WidgetElement.scheduleLabel,
        WidgetElement.todayHeader,
        WidgetElement.counter,
      },
      maximumHabits: 1,
    ),
    WidgetPreset.focus => WidgetConfiguration(
      widgetId: widgetId,
      displayName: displayName,
      preset: preset,
      contentMode: WidgetContentMode.focus,
      showCompleted: false,
      maximumHabits: 1,
    ),
    WidgetPreset.denseList => WidgetConfiguration(
      widgetId: widgetId,
      displayName: displayName,
      preset: preset,
      contentMode: WidgetContentMode.list,
      sortMode: WidgetSortMode.openFirst,
      density: WidgetDensity.compact,
      maximumHabits: 8,
      completionSettings: const WidgetCompletionSettings(
        buttonStyle: WidgetCompletionButtonStyle.checkOnly,
      ),
    ),
    WidgetPreset.dashboard => WidgetConfiguration(
      widgetId: widgetId,
      displayName: displayName,
      preset: preset,
      contentMode: WidgetContentMode.list,
      progressMode: WidgetProgressMode.both,
      maximumHabits: 6,
    ),
  };

  factory WidgetConfiguration.fromJson(String source, {required int widgetId}) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Widget configuration must be an object.');
    }
    return WidgetConfiguration.fromMap(
      Map<String, Object?>.from(decoded),
      widgetId: widgetId,
    );
  }

  factory WidgetConfiguration.fromMap(
    Map<String, Object?> map, {
    required int widgetId,
  }) {
    final serializedWidgetId = (map['widgetId'] as num?)?.toInt();
    if (serializedWidgetId != null && serializedWidgetId != widgetId) {
      throw const FormatException('Widget configuration id does not match.');
    }
    final overrideSource = map['breakpointOverrides'];
    final overrides = <WidgetBreakpoint, WidgetBreakpointOverride>{};
    if (overrideSource is Map) {
      for (final breakpoint in WidgetBreakpoint.values) {
        final value = overrideSource[breakpoint.name];
        if (value is Map) {
          overrides[breakpoint] = WidgetBreakpointOverride.fromMap(
            Map<String, Object?>.from(value),
          );
        }
      }
    }
    final tokens = map['colorTokens'];
    final preset = _enumOr(
      WidgetPreset.values,
      map['preset'],
      WidgetPreset.defaults,
    );
    final baseline = WidgetConfiguration.forPreset(
      widgetId: widgetId,
      preset: preset,
    );
    return WidgetConfiguration(
      schemaVersion: currentSchemaVersion,
      widgetId: widgetId,
      displayName: _displayName(map['displayName']),
      preset: preset,
      habitFilter: _enumOr(
        WidgetHabitFilter.values,
        map['habitFilter'],
        baseline.habitFilter,
      ),
      selectedHabitIds: _strings(map['selectedHabitIds']),
      sortMode: _enumOr(
        WidgetSortMode.values,
        map['sortMode'],
        baseline.sortMode,
      ),
      customHabitOrder: _strings(map['customHabitOrder']),
      contentMode: _enumOr(
        WidgetContentMode.values,
        map['contentMode'],
        baseline.contentMode,
      ),
      themeMode: _enumOr(
        WidgetThemeMode.values,
        map['themeMode'],
        baseline.themeMode,
      ),
      accentMode: _enumOr(
        WidgetAccentMode.values,
        map['accentMode'],
        baseline.accentMode,
      ),
      density: _enumOr(WidgetDensity.values, map['density'], baseline.density),
      showProgress: map['showProgress'] as bool? ?? baseline.showProgress,
      showCompleted: map['showCompleted'] as bool? ?? baseline.showCompleted,
      oneTapCompletion:
          map['oneTapCompletion'] as bool? ?? baseline.oneTapCompletion,
      progressMode: _enumOr(
        WidgetProgressMode.values,
        map['progressMode'],
        baseline.progressMode,
      ),
      maximumHabits:
          _boundedInt(map['maximumHabits'], 1, 12) ?? baseline.maximumHabits,
      colorTokens: tokens is Map
          ? WidgetColorTokens.fromMap(Map<String, Object?>.from(tokens))
          : baseline.colorTokens,
      surfaceTransparency:
          _boundedDouble(map['surfaceTransparency'], 0, 0.4) ??
          baseline.surfaceTransparency,
      listSettings:
          _nested(map['listSettings'], WidgetListSettings.fromMap) ??
          baseline.listSettings,
      progressSettings:
          _nested(map['progressSettings'], WidgetProgressSettings.fromMap) ??
          baseline.progressSettings,
      completionSettings:
          _nested(
            map['completionSettings'],
            WidgetCompletionSettings.fromMap,
          ) ??
          baseline.completionSettings,
      outerPadding: _boundedDouble(map['outerPadding'], 0, 40),
      cornerRadius: _boundedDouble(map['cornerRadius'], 0, 40),
      textScale:
          _boundedDouble(map['textScale'], 0.8, 1.4) ?? baseline.textScale,
      geometry:
          _nested(map['geometry'], WidgetGeometry.fromMap) ?? baseline.geometry,
      typography:
          _nested(map['typography'], WidgetTypography.fromMap) ??
          baseline.typography,
      stateStyles:
          _nested(map['stateStyles'], WidgetStateStyles.fromMap) ??
          baseline.stateStyles,
      interactions:
          _nested(map['interactions'], WidgetInteractionMap.fromMap) ??
          baseline.interactions,
      hiddenElements: map.containsKey('hiddenElements')
          ? _elements(map['hiddenElements'])
          : baseline.hiddenElements,
      breakpointOverrides: overrides,
    );
  }

  static WidgetConfiguration fromJsonOrDefaults(
    String? source, {
    required int widgetId,
  }) {
    if (source == null) return WidgetConfiguration.defaults(widgetId: widgetId);
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return WidgetConfiguration.defaults(widgetId: widgetId);
      }
      final map = Map<String, Object?>.from(decoded);
      final schemaVersion = (map['schemaVersion'] as num?)?.toInt() ?? 0;
      if (schemaVersion > currentSchemaVersion || schemaVersion < 0) {
        return WidgetConfiguration.defaults(widgetId: widgetId);
      }
      return WidgetConfiguration.fromMap(map, widgetId: widgetId);
    } on Object {
      return WidgetConfiguration.defaults(widgetId: widgetId);
    }
  }

  final int schemaVersion;
  final int widgetId;
  final String? displayName;
  final WidgetPreset preset;
  final WidgetHabitFilter habitFilter;
  final List<String> selectedHabitIds;
  final WidgetSortMode sortMode;
  final List<String> customHabitOrder;
  final WidgetContentMode contentMode;
  final WidgetThemeMode themeMode;
  final WidgetAccentMode accentMode;
  final WidgetDensity density;
  final bool showProgress;
  final bool showCompleted;
  final bool oneTapCompletion;
  final WidgetProgressMode progressMode;
  final int? maximumHabits;
  final WidgetColorTokens colorTokens;
  final double surfaceTransparency;
  final WidgetListSettings listSettings;
  final WidgetProgressSettings progressSettings;
  final WidgetCompletionSettings completionSettings;
  final double? outerPadding;
  final double? cornerRadius;
  final double textScale;
  final WidgetGeometry geometry;
  final WidgetTypography typography;
  final WidgetStateStyles stateStyles;
  final WidgetInteractionMap interactions;
  final Set<WidgetElement> hiddenElements;
  final Map<WidgetBreakpoint, WidgetBreakpointOverride> breakpointOverrides;

  EffectiveWidgetConfiguration effectiveFor(WidgetBreakpoint breakpoint) {
    final override = breakpointOverrides[breakpoint];
    final effectiveInteractions = override?.interactions ?? interactions;
    return EffectiveWidgetConfiguration(
      contentMode: override?.contentMode ?? contentMode,
      themeMode: override?.themeMode ?? themeMode,
      accentMode: override?.accentMode ?? accentMode,
      density: override?.density ?? density,
      progressMode: showProgress
          ? (override?.progressMode ?? progressMode)
          : WidgetProgressMode.hidden,
      maximumHabits: override?.maximumHabits ?? maximumHabits,
      outerPadding: override?.outerPadding ?? outerPadding,
      cornerRadius: override?.cornerRadius ?? cornerRadius,
      textScale: override?.textScale ?? textScale,
      colorTokens: override?.colorTokens ?? colorTokens,
      surfaceTransparency: override?.surfaceTransparency ?? surfaceTransparency,
      listSettings: override?.listSettings ?? listSettings,
      progressSettings: override?.progressSettings ?? progressSettings,
      completionSettings: override?.completionSettings ?? completionSettings,
      geometry: geometry.merge(override?.geometry),
      typography: typography.merge(override?.typography),
      stateStyles: override?.stateStyles ?? stateStyles,
      interactions: oneTapCompletion
          ? effectiveInteractions
          : effectiveInteractions.copyWith(
              completionControl: WidgetCompletionAction.openHabit,
            ),
      hiddenElements: <WidgetElement>{
        ...hiddenElements,
        ...?override?.hiddenElements,
        if (!showCompleted) WidgetElement.completedHabits,
      },
    );
  }

  WidgetConfiguration applyPreset(WidgetPreset value) =>
      WidgetConfiguration.forPreset(
        widgetId: widgetId,
        preset: value,
        displayName: displayName,
      ).copyWith(
        habitFilter: habitFilter,
        selectedHabitIds: selectedHabitIds,
        customHabitOrder: customHabitOrder,
      );

  List<WidgetHabitItem> project(Iterable<WidgetHabitItem> habits) {
    final selected = select(habits);
    return showCompleted
        ? selected
        : selected.where((habit) => !habit.isCompleted).toList(growable: false);
  }

  List<WidgetHabitItem> select(Iterable<WidgetHabitItem> habits) {
    var items = habits
        .where((habit) {
          return switch (habitFilter) {
            WidgetHabitFilter.allToday => true,
            WidgetHabitFilter.openOnly => !habit.isCompleted,
            WidgetHabitFilter.selected => selectedHabitIds.contains(habit.id),
          };
        })
        .toList(growable: false);
    if (sortMode == WidgetSortMode.openFirst) {
      final indexed = items.indexed.toList(growable: false)
        ..sort((left, right) {
          final completed = _boolOrder(
            left.$2.isCompleted,
            right.$2.isCompleted,
          );
          return completed != 0 ? completed : left.$1.compareTo(right.$1);
        });
      items = indexed.map((item) => item.$2).toList(growable: false);
    }
    if (sortMode == WidgetSortMode.custom) {
      final order = <String, int>{
        for (final item in customHabitOrder.indexed) item.$2: item.$1,
      };
      final indexed = items.indexed.toList(growable: false)
        ..sort((left, right) {
          final leftOrder = order[left.$2.id] ?? (order.length + left.$1);
          final rightOrder = order[right.$2.id] ?? (order.length + right.$1);
          return leftOrder.compareTo(rightOrder);
        });
      items = indexed.map((item) => item.$2).toList(growable: false);
    }
    final pinned = listSettings.pinnedHabitIds.toSet();
    if (pinned.isNotEmpty) {
      items = <WidgetHabitItem>[
        ...items.where((item) => pinned.contains(item.id)),
        ...items.where((item) => !pinned.contains(item.id)),
      ];
    }
    if (listSettings.completedPlacement == WidgetCompletedPlacement.end) {
      items = <WidgetHabitItem>[
        ...items.where((item) => !item.isCompleted),
        ...items.where((item) => item.isCompleted),
      ];
    }
    return items;
  }

  WidgetConfiguration copyWith({
    String? displayName,
    bool clearDisplayName = false,
    WidgetPreset? preset,
    WidgetHabitFilter? habitFilter,
    Iterable<String>? selectedHabitIds,
    WidgetSortMode? sortMode,
    Iterable<String>? customHabitOrder,
    WidgetContentMode? contentMode,
    WidgetThemeMode? themeMode,
    WidgetAccentMode? accentMode,
    WidgetDensity? density,
    bool? showProgress,
    bool? showCompleted,
    bool? oneTapCompletion,
    WidgetProgressMode? progressMode,
    int? maximumHabits,
    bool clearMaximumHabits = false,
    WidgetColorTokens? colorTokens,
    double? surfaceTransparency,
    WidgetListSettings? listSettings,
    WidgetProgressSettings? progressSettings,
    WidgetCompletionSettings? completionSettings,
    double? outerPadding,
    bool clearOuterPadding = false,
    double? cornerRadius,
    bool clearCornerRadius = false,
    double? textScale,
    WidgetGeometry? geometry,
    WidgetTypography? typography,
    WidgetStateStyles? stateStyles,
    WidgetInteractionMap? interactions,
    Iterable<WidgetElement>? hiddenElements,
    Map<WidgetBreakpoint, WidgetBreakpointOverride>? breakpointOverrides,
  }) => WidgetConfiguration(
    widgetId: widgetId,
    displayName: clearDisplayName ? null : (displayName ?? this.displayName),
    preset: preset ?? this.preset,
    habitFilter: habitFilter ?? this.habitFilter,
    selectedHabitIds: selectedHabitIds ?? this.selectedHabitIds,
    sortMode: sortMode ?? this.sortMode,
    customHabitOrder: customHabitOrder ?? this.customHabitOrder,
    contentMode: contentMode ?? this.contentMode,
    themeMode: themeMode ?? this.themeMode,
    accentMode: accentMode ?? this.accentMode,
    density: density ?? this.density,
    showProgress: showProgress ?? this.showProgress,
    showCompleted: showCompleted ?? this.showCompleted,
    oneTapCompletion: oneTapCompletion ?? this.oneTapCompletion,
    progressMode: progressMode ?? this.progressMode,
    maximumHabits: clearMaximumHabits
        ? null
        : (maximumHabits ?? this.maximumHabits),
    colorTokens: colorTokens ?? this.colorTokens,
    surfaceTransparency: surfaceTransparency ?? this.surfaceTransparency,
    listSettings: listSettings ?? this.listSettings,
    progressSettings: progressSettings ?? this.progressSettings,
    completionSettings: completionSettings ?? this.completionSettings,
    outerPadding: clearOuterPadding
        ? null
        : (outerPadding ?? this.outerPadding),
    cornerRadius: clearCornerRadius
        ? null
        : (cornerRadius ?? this.cornerRadius),
    textScale: textScale ?? this.textScale,
    geometry: geometry ?? this.geometry,
    typography: typography ?? this.typography,
    stateStyles: stateStyles ?? this.stateStyles,
    interactions: interactions ?? this.interactions,
    hiddenElements: hiddenElements ?? this.hiddenElements,
    breakpointOverrides: breakpointOverrides ?? this.breakpointOverrides,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'schemaVersion': currentSchemaVersion,
    'widgetId': widgetId,
    if (displayName != null) 'displayName': displayName,
    'preset': preset.name,
    'habitFilter': habitFilter.name,
    'selectedHabitIds': selectedHabitIds,
    'sortMode': sortMode.name,
    'customHabitOrder': customHabitOrder,
    'contentMode': contentMode.name,
    'themeMode': themeMode.name,
    'accentMode': accentMode.name,
    'density': density.name,
    'showProgress': showProgress,
    'showCompleted': showCompleted,
    'oneTapCompletion': oneTapCompletion,
    'progressMode': progressMode.name,
    if (maximumHabits != null) 'maximumHabits': maximumHabits,
    if (!colorTokens.isEmpty) 'colorTokens': colorTokens.toMap(),
    'surfaceTransparency': surfaceTransparency,
    'listSettings': listSettings.toMap(),
    'progressSettings': progressSettings.toMap(),
    'completionSettings': completionSettings.toMap(),
    if (outerPadding != null) 'outerPadding': outerPadding,
    if (cornerRadius != null) 'cornerRadius': cornerRadius,
    'textScale': textScale,
    'geometry': geometry.toMap(),
    'typography': typography.toMap(),
    'stateStyles': stateStyles.toMap(),
    'interactions': interactions.toMap(),
    'hiddenElements': hiddenElements.map((item) => item.name).toList(),
    'breakpointOverrides': <String, Object?>{
      for (final entry in breakpointOverrides.entries)
        entry.key.name: entry.value.toMap(),
    },
  };

  String toJson() => jsonEncode(toMap());
}

T _enumOr<T extends Enum>(List<T> values, Object? source, T fallback) =>
    _enumOrNull(values, source) ?? fallback;

T? _enumOrNull<T extends Enum>(List<T> values, Object? source) {
  if (source is! String) return null;
  for (final value in values) {
    if (value.name == source) return value;
  }
  return null;
}

List<String> _strings(Object? source) => source is List
    ? source.whereType<String>().where((value) => value.isNotEmpty).toList()
    : const <String>[];

Set<WidgetElement> _elements(Object? source) => source is List
    ? source
          .whereType<String>()
          .map((name) => _enumOrNull(WidgetElement.values, name))
          .whereType<WidgetElement>()
          .toSet()
    : const <WidgetElement>{};

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

String? _displayName(Object? source) {
  if (source is! String) return null;
  final value = source.trim();
  return value.isEmpty
      ? null
      : value.substring(0, value.length > 48 ? 48 : value.length);
}

int _boolOrder(bool left, bool right) => left == right ? 0 : (left ? 1 : -1);

T? _nested<T>(Object? source, T Function(Map<String, Object?>) parse) =>
    source is Map ? parse(Map<String, Object?>.from(source)) : null;
