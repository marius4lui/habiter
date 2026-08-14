import '../../../models/habit.dart';
import '../../../utils/habit_utils.dart';

final class AnalyticsController {
  HabitStats statsFor(Habit habit, List<HabitEntry> entries) =>
      calculateHabitStats(habit, entries);
}
