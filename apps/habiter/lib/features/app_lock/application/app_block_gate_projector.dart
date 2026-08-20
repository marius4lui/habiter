import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../domain/app_block_config.dart';
import '../domain/app_block_projection.dart';
import '../domain/app_lock_gateway.dart';
import 'app_block_gate_evaluator.dart';

final class AppBlockGateProjector {
  const AppBlockGateProjector({
    AppBlockGateEvaluator evaluator = const AppBlockGateEvaluator(),
  }) : _evaluator = evaluator;

  final AppBlockGateEvaluator _evaluator;

  AppBlockProjectionSnapshot project({
    required AppBlockConfig config,
    required AppLockPermissionSnapshot permissions,
    required LocalDate date,
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
    Set<String>? installedPackages,
  }) {
    if (!config.isEnabled || !permissions.ready) {
      return AppBlockProjectionSnapshot(const <AppBlockGateProjection>[]);
    }

    final projections =
        config.activeRules
            .where(
              (rule) =>
                  installedPackages == null ||
                  installedPackages.contains(rule.packageName),
            )
            .map((rule) {
              final evaluation = _evaluator.evaluate(
                requirement: rule.requirement,
                date: date,
                habits: habits,
                entries: entries,
              );
              return AppBlockGateProjection(
                packageName: rule.packageName,
                appName: rule.appName,
                blockers: evaluation.blockers,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => a.packageName.compareTo(b.packageName));
    return AppBlockProjectionSnapshot(projections);
  }
}
