import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../today/application/today_query.dart';
import '../domain/widget_habit_item.dart';
import '../domain/widget_snapshot.dart';

final class WidgetSnapshotMapper {
  const WidgetSnapshotMapper();

  WidgetSnapshot map({
    required DateTime generatedAt,
    required LocalDate date,
    required String locale,
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
    WidgetLastCompletion? lastCompletion,
  }) {
    final today = TodayQuery.forDate(
      date: date,
      habits: habits,
      entries: entries,
    );
    final completedIds = today.completed.map((habit) => habit.id).toSet();
    final items = today.scheduled
        .map(
          (habit) => WidgetHabitItem(
            id: habit.id,
            name: habit.name,
            icon: habit.icon,
            isCompleted: completedIds.contains(habit.id),
            scheduleLabel: _scheduleLabel(habit, locale),
          ),
        )
        .toList(growable: false);
    return WidgetSnapshot(
      generatedAt: generatedAt,
      localDate: date.toString(),
      locale: locale,
      completedCount: today.completed.length,
      scheduledCount: today.scheduled.length,
      allComplete: today.scheduled.isNotEmpty && today.pending.isEmpty,
      hasAnyHabits: habits.isNotEmpty,
      nextHabit: items.where((item) => !item.isCompleted).firstOrNull,
      habits: items,
      lastCompletion: lastCompletion,
    );
  }

  String _scheduleLabel(Habit habit, String locale) {
    final german = locale.toLowerCase().startsWith('de');
    return switch (habit.frequency) {
      HabitFrequency.daily => german ? 'Täglich' : 'Daily',
      HabitFrequency.weekly =>
        german
            ? '${habit.targetCount}× pro Woche'
            : '${habit.targetCount}× per week',
      HabitFrequency.custom => german ? 'Bestimmte Tage' : 'Specific days',
    };
  }
}
