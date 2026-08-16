import 'dart:collection';
import 'dart:convert';

import 'widget_habit_item.dart';

final class WidgetLastCompletion {
  const WidgetLastCompletion({
    required this.habitId,
    required this.habitName,
    required this.actionId,
    required this.completedAt,
  });

  factory WidgetLastCompletion.fromMap(Map<String, Object?> map) =>
      WidgetLastCompletion(
        habitId: map['habitId']! as String,
        habitName: map['habitName']! as String,
        actionId: map['actionId']! as String,
        completedAt: DateTime.parse(map['completedAt']! as String),
      );

  final String habitId;
  final String habitName;
  final String actionId;
  final DateTime completedAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'habitId': habitId,
    'habitName': habitName,
    'actionId': actionId,
    'completedAt': completedAt.toUtc().toIso8601String(),
  };
}

final class WidgetSnapshot {
  WidgetSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.generatedAt,
    required this.localDate,
    required this.locale,
    required this.completedCount,
    required this.scheduledCount,
    required this.allComplete,
    required Iterable<WidgetHabitItem> habits,
    this.nextHabit,
    this.lastCompletion,
  }) : habits = UnmodifiableListView<WidgetHabitItem>(habits.toList());

  static const currentSchemaVersion = 1;

  factory WidgetSnapshot.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Widget snapshot must be a JSON object.');
    }
    final map = Map<String, Object?>.from(decoded);
    final habits = ((map['habits'] as List<Object?>?) ?? const <Object?>[])
        .map(
          (value) =>
              WidgetHabitItem.fromMap(Map<String, Object?>.from(value! as Map)),
        )
        .toList(growable: false);
    final next = map['nextHabit'];
    final completion = map['lastCompletion'];
    return WidgetSnapshot(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      generatedAt: DateTime.parse(map['generatedAt']! as String),
      localDate: map['localDate']! as String,
      locale: map['locale']! as String,
      completedCount: (map['completedCount']! as num).toInt(),
      scheduledCount: (map['scheduledCount']! as num).toInt(),
      allComplete: map['allComplete']! as bool,
      habits: habits,
      nextHabit: next is Map
          ? WidgetHabitItem.fromMap(Map<String, Object?>.from(next))
          : null,
      lastCompletion: completion is Map
          ? WidgetLastCompletion.fromMap(Map<String, Object?>.from(completion))
          : null,
    );
  }

  final int schemaVersion;
  final DateTime generatedAt;
  final String localDate;
  final String locale;
  final int completedCount;
  final int scheduledCount;
  final bool allComplete;
  final WidgetHabitItem? nextHabit;
  final List<WidgetHabitItem> habits;
  final WidgetLastCompletion? lastCompletion;

  String toJson() => jsonEncode(<String, Object?>{
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'localDate': localDate,
    'locale': locale,
    'completedCount': completedCount,
    'scheduledCount': scheduledCount,
    'allComplete': allComplete,
    'nextHabit': nextHabit?.toMap(),
    'habits': habits.map((habit) => habit.toMap()).toList(growable: false),
    'lastCompletion': lastCompletion?.toMap(),
  });
}
