import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/analytics/domain/habit_metrics.dart';
import 'package:habiter/features/coaching/domain/recovery_summary.dart';
import 'package:habiter/models/habit.dart';

void main() {
  test(
    'support score is transparent and derived without historical writes',
    () {
      final metrics = HabitMetrics(
        scheduled: 10,
        completed: 6,
        currentStreak: 2,
        longestStreak: 4,
        weeks: const <WeeklyHabitMetric>[],
      );

      final summary = RecoverySummary.fromMetrics(metrics);

      expect(summary.score, 60);
      expect(summary.state, RecoveryState.rebuilding);
      expect(metrics.completed, 6);
    },
  );

  test('empty and low histories use neutral return states', () {
    RecoverySummary summary(int scheduled, int completed) =>
        RecoverySummary.fromMetrics(
          HabitMetrics(
            scheduled: scheduled,
            completed: completed,
            currentStreak: 0,
            longestStreak: 0,
            weeks: const <WeeklyHabitMetric>[],
          ),
        );

    expect(summary(0, 0).state, RecoveryState.newStart);
    expect(summary(10, 2).state, RecoveryState.gentleReturn);
    expect(summary(10, 8).state, RecoveryState.steady);
  });

  test('recovery preference roundtrips and defaults on for legacy data', () {
    final legacy = UserPreferences.fromMap(<String, dynamic>{
      'theme': 'system',
      'notifications': false,
      'reminderTime': '20:00',
      'aiInsights': false,
      'language': 'de',
    });
    expect(legacy.showRecoverySupport, isTrue);

    final hidden = legacy.copyWith(showRecoverySupport: false);
    expect(
      UserPreferences.fromMap(hidden.toMap()).showRecoverySupport,
      isFalse,
    );
  });
}
