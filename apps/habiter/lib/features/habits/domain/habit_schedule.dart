import 'package:collection/collection.dart';

import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';

sealed class HabitSchedule {
  const HabitSchedule();

  factory HabitSchedule.fromMap(Map<String, Object?> map) {
    return switch (map['type']) {
      'daily' => const DailySchedule(),
      'weekdays' => WeekdaySchedule(
        ((map['weekdays'] as List<Object?>?) ?? const <Object?>[]).map(
          (value) => (value as num).toInt(),
        ),
      ),
      'timesPerWeek' => TimesPerWeekSchedule(
        (map['target'] as num?)?.toInt() ?? 0,
      ),
      final Object? type => throw FormatException(
        'Unknown habit schedule type: $type',
      ),
    };
  }

  int get weeklyTarget;

  bool isAvailableOn(LocalDate date);

  Map<String, Object?> toMap();

  List<LocalDate> datesBetween(LocalDate start, LocalDate end) {
    if (end.compareTo(start) < 0) return const <LocalDate>[];
    final result = <LocalDate>[];
    for (var date = start; date.compareTo(end) <= 0; date = date.addDays(1)) {
      if (isAvailableOn(date)) result.add(date);
    }
    return List<LocalDate>.unmodifiable(result);
  }
}

final class DailySchedule extends HabitSchedule {
  const DailySchedule();

  @override
  int get weeklyTarget => 7;

  @override
  bool isAvailableOn(LocalDate date) => true;

  @override
  Map<String, Object?> toMap() => const <String, Object?>{'type': 'daily'};

  @override
  bool operator ==(Object other) => other is DailySchedule;

  @override
  int get hashCode => 0x4441494c;
}

final class WeekdaySchedule extends HabitSchedule {
  factory WeekdaySchedule(Iterable<int> weekdays) {
    final values = weekdays.toSet().toList()..sort();
    if (values.isEmpty || values.any((day) => day < 1 || day > 7)) {
      throw ArgumentError.value(
        values,
        'weekdays',
        'Must contain one or more ISO weekdays from 1 through 7.',
      );
    }
    return WeekdaySchedule._(values);
  }

  WeekdaySchedule._(List<int> weekdays)
    : weekdays = UnmodifiableListView<int>(weekdays);

  final List<int> weekdays;

  @override
  int get weeklyTarget => weekdays.length;

  @override
  bool isAvailableOn(LocalDate date) => weekdays.contains(date.weekday);

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'type': 'weekdays',
    'weekdays': weekdays,
  };

  @override
  bool operator ==(Object other) {
    return other is WeekdaySchedule &&
        const ListEquality<int>().equals(weekdays, other.weekdays);
  }

  @override
  int get hashCode => const ListEquality<int>().hash(weekdays);
}

final class TimesPerWeekSchedule extends HabitSchedule {
  factory TimesPerWeekSchedule(int target) {
    if (target < 1 || target > 7) {
      throw ArgumentError.value(target, 'target', 'Must be between 1 and 7.');
    }
    return TimesPerWeekSchedule._(target);
  }

  const TimesPerWeekSchedule._(this.target);

  final int target;

  @override
  int get weeklyTarget => target;

  @override
  bool isAvailableOn(LocalDate date) => true;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'type': 'timesPerWeek',
    'target': target,
  };

  @override
  bool operator ==(Object other) {
    return other is TimesPerWeekSchedule && target == other.target;
  }

  @override
  int get hashCode => target.hashCode;
}

abstract final class LegacyHabitScheduleMapper {
  static HabitSchedule fromHabit(Habit habit) {
    return switch (habit.frequency) {
      HabitFrequency.daily => const DailySchedule(),
      HabitFrequency.weekly => TimesPerWeekSchedule(habit.targetCount),
      HabitFrequency.custom => _custom(habit.customDays),
    };
  }

  static HabitSchedule _custom(List<int>? customDays) {
    if (customDays == null || customDays.isEmpty) {
      throw const FormatException(
        'A custom legacy schedule must contain at least one weekday.',
      );
    }
    try {
      return WeekdaySchedule(customDays);
    } on ArgumentError catch (error) {
      throw FormatException('Invalid custom legacy schedule.', error);
    }
  }
}
