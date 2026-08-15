import 'dart:collection';

import '../../../../models/habit.dart';
import '../../domain/habit_source.dart';

const _unset = Object();

final class HabitEditorDraft {
  HabitEditorDraft({
    required this.name,
    this.description,
    required this.category,
    required this.frequency,
    required this.targetCount,
    required this.color,
    required this.icon,
    Iterable<int>? customDays,
    required this.notificationEnabled,
    this.notificationTime,
  }) : customDays = UnmodifiableListView<int>(
         (customDays ?? const <int>[]).toSet().toList()..sort(),
       );

  factory HabitEditorDraft.initial() => HabitEditorDraft(
    name: '',
    category: 'Health',
    frequency: HabitFrequency.daily,
    targetCount: 1,
    color: '#285943',
    icon: '✓',
    notificationEnabled: false,
  );

  factory HabitEditorDraft.fromHabit(Habit habit) => HabitEditorDraft(
    name: habit.name,
    description: habit.description,
    category: habit.category,
    frequency: habit.frequency,
    targetCount: habit.targetCount,
    color: habit.color,
    icon: habit.icon,
    customDays: habit.customDays,
    notificationEnabled: habit.notificationEnabled,
    notificationTime: habit.notificationTime,
  );

  final String name;
  final String? description;
  final String category;
  final HabitFrequency frequency;
  final int targetCount;
  final String color;
  final String icon;
  final List<int> customDays;
  final bool notificationEnabled;
  final String? notificationTime;

  HabitEditorDraft copyWith({
    String? name,
    Object? description = _unset,
    String? category,
    HabitFrequency? frequency,
    int? targetCount,
    String? color,
    String? icon,
    Iterable<int>? customDays,
    bool? notificationEnabled,
    Object? notificationTime = _unset,
  }) => HabitEditorDraft(
    name: name ?? this.name,
    description: identical(description, _unset)
        ? this.description
        : description as String?,
    category: category ?? this.category,
    frequency: frequency ?? this.frequency,
    targetCount: targetCount ?? this.targetCount,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    customDays: customDays ?? this.customDays,
    notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    notificationTime: identical(notificationTime, _unset)
        ? this.notificationTime
        : notificationTime as String?,
  );

  Map<String, String> validate() {
    final errors = <String, String>{};
    if (name.trim().isEmpty) errors['name'] = 'required';
    if (targetCount < 1 || targetCount > 99) errors['targetCount'] = 'range';
    if (frequency == HabitFrequency.custom &&
        (customDays.isEmpty || customDays.any((day) => day < 1 || day > 7))) {
      errors['customDays'] = 'required';
    }
    if (notificationEnabled &&
        !RegExp(
          r'^(?:[01]\d|2[0-3]):[0-5]\d$',
        ).hasMatch(notificationTime ?? '')) {
      errors['notificationTime'] = 'invalid';
    }
    return Map<String, String>.unmodifiable(errors);
  }

  Habit toHabit({
    required String id,
    required DateTime createdAt,
    bool isActive = true,
    Iterable<HabitPause> pauses = const <HabitPause>[],
    DateTime? archivedAt,
    DateTime? restoredAt,
    HabitSourceMetadata? source,
  }) => Habit(
    id: id,
    name: name.trim(),
    description: description?.trim().isEmpty == true
        ? null
        : description?.trim(),
    color: color,
    icon: icon,
    frequency: frequency,
    targetCount: targetCount,
    category: category.trim(),
    customDays: frequency == HabitFrequency.custom ? customDays : null,
    createdAt: createdAt,
    isActive: isActive,
    notificationEnabled: notificationEnabled,
    notificationTime: notificationEnabled ? notificationTime : null,
    pauses: pauses,
    archivedAt: archivedAt,
    restoredAt: restoredAt,
    source: source,
  );
}
