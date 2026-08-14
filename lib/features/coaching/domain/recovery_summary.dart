import '../../analytics/domain/habit_metrics.dart';

enum RecoveryState { newStart, gentleReturn, rebuilding, steady }

final class RecoverySummary {
  const RecoverySummary({
    required this.state,
    required this.score,
    required this.scheduled,
    required this.completed,
  });

  final RecoveryState state;
  final int score;
  final int scheduled;
  final int completed;

  /// The score is derived only: completed scheduled occurrences divided by
  /// eligible scheduled occurrences. Paused and archived dates never enter the
  /// denominator and this calculation never mutates history.
  factory RecoverySummary.fromMetrics(HabitMetrics metrics) {
    final score = metrics.scheduled == 0
        ? 0
        : (metrics.completionRate * 100).round().clamp(0, 100) as int;
    final state = metrics.scheduled == 0
        ? RecoveryState.newStart
        : score >= 80
        ? RecoveryState.steady
        : score >= 50
        ? RecoveryState.rebuilding
        : RecoveryState.gentleReturn;
    return RecoverySummary(
      state: state,
      score: score,
      scheduled: metrics.scheduled,
      completed: metrics.completed,
    );
  }
}
