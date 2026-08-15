import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../domain/habit_metrics.dart';
import '../../../utils/habit_utils.dart';

final class AnalyticsController {
  const AnalyticsController(this._clock);

  final Clock _clock;

  HabitMetrics metricsFor(Habit habit, List<HabitEntry> entries) =>
      HabitMetricCalculator.calculate(
        habit: habit,
        entries: entries,
        through: LocalDate.fromDateTime(_clock.now()),
      );

  HabitStats statsFor(Habit habit, List<HabitEntry> entries) =>
      calculateHabitStats(habit, entries);
}
