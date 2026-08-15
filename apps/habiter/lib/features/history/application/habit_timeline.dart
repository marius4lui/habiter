import '../../../models/habit.dart';

enum HabitTimelineEventType { created, paused, resumed, archived, restored }

final class HabitTimelineEvent {
  const HabitTimelineEvent({required this.type, required this.at});
  final HabitTimelineEventType type;
  final DateTime at;
}

abstract final class HabitTimeline {
  static List<HabitTimelineEvent> forHabit(Habit habit) {
    final events = <HabitTimelineEvent>[
      HabitTimelineEvent(
        type: HabitTimelineEventType.created,
        at: habit.createdAt,
      ),
      for (final pause in habit.pauses) ...<HabitTimelineEvent>[
        HabitTimelineEvent(
          type: HabitTimelineEventType.paused,
          at: pause.startedAt,
        ),
        if (pause.endedAt case final DateTime endedAt)
          HabitTimelineEvent(type: HabitTimelineEventType.resumed, at: endedAt),
      ],
      if (habit.archivedAt case final DateTime archivedAt)
        HabitTimelineEvent(
          type: HabitTimelineEventType.archived,
          at: archivedAt,
        ),
      if (habit.restoredAt case final DateTime restoredAt)
        HabitTimelineEvent(
          type: HabitTimelineEventType.restored,
          at: restoredAt,
        ),
    ]..sort((left, right) => left.at.compareTo(right.at));
    return List<HabitTimelineEvent>.unmodifiable(events);
  }
}
