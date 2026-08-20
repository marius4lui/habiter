enum AppBlockGateKind { daily, scheduledDay, weeklyContribution }

final class AppBlockHabitGate {
  const AppBlockHabitGate({
    required this.habitId,
    required this.habitName,
    required this.kind,
    this.weeklyProgress,
    this.weeklyTarget,
  });

  final String habitId;
  final String habitName;
  final AppBlockGateKind kind;
  final int? weeklyProgress;
  final int? weeklyTarget;

  String get progressLabel => switch ((weeklyProgress, weeklyTarget)) {
    (final int progress, final int target) => '$progress/$target this week',
    _ => 'Open today',
  };
}

final class AppBlockGateEvaluation {
  AppBlockGateEvaluation(Iterable<AppBlockHabitGate> blockers)
    : blockers = List<AppBlockHabitGate>.unmodifiable(blockers);

  final List<AppBlockHabitGate> blockers;
  bool get blocked => blockers.isNotEmpty;
}
