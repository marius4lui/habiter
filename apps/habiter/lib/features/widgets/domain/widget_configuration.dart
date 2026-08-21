import 'dart:collection';
import 'dart:convert';

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
    this.progressMode,
    this.maximumHabits,
    this.outerPadding,
    this.cornerRadius,
    this.textScale,
    this.hiddenElements = const <WidgetElement>{},
  });

  factory WidgetBreakpointOverride.fromMap(Map<String, Object?> map) =>
      WidgetBreakpointOverride(
        contentMode: _enumOrNull(WidgetContentMode.values, map['contentMode']),
        progressMode: _enumOrNull(
          WidgetProgressMode.values,
          map['progressMode'],
        ),
        maximumHabits: _boundedInt(map['maximumHabits'], 1, 12),
        outerPadding: _boundedDouble(map['outerPadding'], 0, 40),
        cornerRadius: _boundedDouble(map['cornerRadius'], 0, 40),
        textScale: _boundedDouble(map['textScale'], 0.8, 1.4),
        hiddenElements: _elements(map['hiddenElements']),
      );

  final WidgetContentMode? contentMode;
  final WidgetProgressMode? progressMode;
  final int? maximumHabits;
  final double? outerPadding;
  final double? cornerRadius;
  final double? textScale;
  final Set<WidgetElement> hiddenElements;

  bool get isEmpty =>
      contentMode == null &&
      progressMode == null &&
      maximumHabits == null &&
      outerPadding == null &&
      cornerRadius == null &&
      textScale == null &&
      hiddenElements.isEmpty;

  Map<String, Object?> toMap() => <String, Object?>{
    if (contentMode != null) 'contentMode': contentMode!.name,
    if (progressMode != null) 'progressMode': progressMode!.name,
    if (maximumHabits != null) 'maximumHabits': maximumHabits,
    if (outerPadding != null) 'outerPadding': outerPadding,
    if (cornerRadius != null) 'cornerRadius': cornerRadius,
    if (textScale != null) 'textScale': textScale,
    if (hiddenElements.isNotEmpty)
      'hiddenElements': hiddenElements.map((item) => item.name).toList(),
  };
}

final class EffectiveWidgetConfiguration {
  const EffectiveWidgetConfiguration({
    required this.contentMode,
    required this.progressMode,
    required this.maximumHabits,
    required this.outerPadding,
    required this.cornerRadius,
    required this.textScale,
    required this.hiddenElements,
  });

  final WidgetContentMode contentMode;
  final WidgetProgressMode progressMode;
  final int? maximumHabits;
  final double? outerPadding;
  final double? cornerRadius;
  final double textScale;
  final Set<WidgetElement> hiddenElements;

  bool shows(WidgetElement element) => !hiddenElements.contains(element);
}

final class WidgetConfiguration {
  WidgetConfiguration({
    this.schemaVersion = currentSchemaVersion,
    required this.widgetId,
    this.displayName,
    this.habitFilter = WidgetHabitFilter.allToday,
    Iterable<String> selectedHabitIds = const <String>[],
    this.sortMode = WidgetSortMode.asInHabiter,
    Iterable<String> customHabitOrder = const <String>[],
    this.contentMode = WidgetContentMode.auto,
    this.themeMode = WidgetThemeMode.system,
    this.showProgress = true,
    this.showCompleted = true,
    this.oneTapCompletion = true,
    this.progressMode = WidgetProgressMode.automatic,
    this.maximumHabits,
    this.colorTokens = const WidgetColorTokens(),
    this.outerPadding,
    this.cornerRadius,
    this.textScale = 1,
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
    final schemaVersion = _boundedInt(map['schemaVersion'], 0, 1) ?? 0;
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
    return WidgetConfiguration(
      schemaVersion: currentSchemaVersion,
      widgetId: widgetId,
      displayName: _displayName(map['displayName']),
      habitFilter: _enumOr(
        WidgetHabitFilter.values,
        map['habitFilter'],
        WidgetHabitFilter.allToday,
      ),
      selectedHabitIds: _strings(map['selectedHabitIds']),
      sortMode: _enumOr(
        WidgetSortMode.values,
        map['sortMode'],
        WidgetSortMode.asInHabiter,
      ),
      customHabitOrder: _strings(map['customHabitOrder']),
      contentMode: _enumOr(
        WidgetContentMode.values,
        map['contentMode'],
        WidgetContentMode.auto,
      ),
      themeMode: _enumOr(
        WidgetThemeMode.values,
        map['themeMode'],
        WidgetThemeMode.system,
      ),
      showProgress: map['showProgress'] as bool? ?? true,
      showCompleted: map['showCompleted'] as bool? ?? true,
      oneTapCompletion: map['oneTapCompletion'] as bool? ?? true,
      progressMode: _enumOr(
        WidgetProgressMode.values,
        map['progressMode'],
        WidgetProgressMode.automatic,
      ),
      maximumHabits: _boundedInt(map['maximumHabits'], 1, 12),
      colorTokens: tokens is Map
          ? WidgetColorTokens.fromMap(Map<String, Object?>.from(tokens))
          : const WidgetColorTokens(),
      outerPadding: _boundedDouble(map['outerPadding'], 0, 40),
      cornerRadius: _boundedDouble(map['cornerRadius'], 0, 40),
      textScale: _boundedDouble(map['textScale'], 0.8, 1.4) ?? 1,
      hiddenElements: _elements(map['hiddenElements']),
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
      if (decoded is! Map)
        return WidgetConfiguration.defaults(widgetId: widgetId);
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
  final WidgetHabitFilter habitFilter;
  final List<String> selectedHabitIds;
  final WidgetSortMode sortMode;
  final List<String> customHabitOrder;
  final WidgetContentMode contentMode;
  final WidgetThemeMode themeMode;
  final bool showProgress;
  final bool showCompleted;
  final bool oneTapCompletion;
  final WidgetProgressMode progressMode;
  final int? maximumHabits;
  final WidgetColorTokens colorTokens;
  final double? outerPadding;
  final double? cornerRadius;
  final double textScale;
  final Set<WidgetElement> hiddenElements;
  final Map<WidgetBreakpoint, WidgetBreakpointOverride> breakpointOverrides;

  EffectiveWidgetConfiguration effectiveFor(WidgetBreakpoint breakpoint) {
    final override = breakpointOverrides[breakpoint];
    return EffectiveWidgetConfiguration(
      contentMode: override?.contentMode ?? contentMode,
      progressMode: showProgress
          ? (override?.progressMode ?? progressMode)
          : WidgetProgressMode.hidden,
      maximumHabits: override?.maximumHabits ?? maximumHabits,
      outerPadding: override?.outerPadding ?? outerPadding,
      cornerRadius: override?.cornerRadius ?? cornerRadius,
      textScale: override?.textScale ?? textScale,
      hiddenElements: <WidgetElement>{
        ...hiddenElements,
        ...?override?.hiddenElements,
        if (!showCompleted) WidgetElement.completedHabits,
      },
    );
  }

  List<WidgetHabitItem> project(Iterable<WidgetHabitItem> habits) {
    var items = habits
        .where((habit) {
          if (!showCompleted && habit.isCompleted) return false;
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
      return indexed.map((item) => item.$2).toList(growable: false);
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
      return indexed.map((item) => item.$2).toList(growable: false);
    }
    return items;
  }

  WidgetConfiguration copyWith({
    String? displayName,
    bool clearDisplayName = false,
    WidgetHabitFilter? habitFilter,
    Iterable<String>? selectedHabitIds,
    WidgetSortMode? sortMode,
    Iterable<String>? customHabitOrder,
    WidgetContentMode? contentMode,
    WidgetThemeMode? themeMode,
    bool? showProgress,
    bool? showCompleted,
    bool? oneTapCompletion,
    WidgetProgressMode? progressMode,
    int? maximumHabits,
    bool clearMaximumHabits = false,
    WidgetColorTokens? colorTokens,
    double? outerPadding,
    bool clearOuterPadding = false,
    double? cornerRadius,
    bool clearCornerRadius = false,
    double? textScale,
    Iterable<WidgetElement>? hiddenElements,
    Map<WidgetBreakpoint, WidgetBreakpointOverride>? breakpointOverrides,
  }) => WidgetConfiguration(
    widgetId: widgetId,
    displayName: clearDisplayName ? null : (displayName ?? this.displayName),
    habitFilter: habitFilter ?? this.habitFilter,
    selectedHabitIds: selectedHabitIds ?? this.selectedHabitIds,
    sortMode: sortMode ?? this.sortMode,
    customHabitOrder: customHabitOrder ?? this.customHabitOrder,
    contentMode: contentMode ?? this.contentMode,
    themeMode: themeMode ?? this.themeMode,
    showProgress: showProgress ?? this.showProgress,
    showCompleted: showCompleted ?? this.showCompleted,
    oneTapCompletion: oneTapCompletion ?? this.oneTapCompletion,
    progressMode: progressMode ?? this.progressMode,
    maximumHabits: clearMaximumHabits
        ? null
        : (maximumHabits ?? this.maximumHabits),
    colorTokens: colorTokens ?? this.colorTokens,
    outerPadding: clearOuterPadding
        ? null
        : (outerPadding ?? this.outerPadding),
    cornerRadius: clearCornerRadius
        ? null
        : (cornerRadius ?? this.cornerRadius),
    textScale: textScale ?? this.textScale,
    hiddenElements: hiddenElements ?? this.hiddenElements,
    breakpointOverrides: breakpointOverrides ?? this.breakpointOverrides,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'schemaVersion': currentSchemaVersion,
    'widgetId': widgetId,
    if (displayName != null) 'displayName': displayName,
    'habitFilter': habitFilter.name,
    'selectedHabitIds': selectedHabitIds,
    'sortMode': sortMode.name,
    'customHabitOrder': customHabitOrder,
    'contentMode': contentMode.name,
    'themeMode': themeMode.name,
    'showProgress': showProgress,
    'showCompleted': showCompleted,
    'oneTapCompletion': oneTapCompletion,
    'progressMode': progressMode.name,
    if (maximumHabits != null) 'maximumHabits': maximumHabits,
    if (!colorTokens.isEmpty) 'colorTokens': colorTokens.toMap(),
    if (outerPadding != null) 'outerPadding': outerPadding,
    if (cornerRadius != null) 'cornerRadius': cornerRadius,
    'textScale': textScale,
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
