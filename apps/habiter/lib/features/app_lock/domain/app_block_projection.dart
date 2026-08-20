import 'app_block_gate.dart';

final class AppBlockGateProjection {
  AppBlockGateProjection({
    required this.packageName,
    required this.appName,
    required Iterable<AppBlockHabitGate> blockers,
  }) : blockers = List<AppBlockHabitGate>.unmodifiable(blockers);

  final String packageName;
  final String appName;
  final List<AppBlockHabitGate> blockers;
  bool get blocked => blockers.isNotEmpty;

  Map<String, Object?> toMap() => <String, Object?>{
    'packageName': packageName,
    'appName': appName,
    'blocked': blocked,
    'blockers': blockers
        .map(
          (gate) => <String, Object?>{
            'habitId': gate.habitId,
            'name': gate.habitName,
            'progress': gate.progressLabel,
          },
        )
        .toList(growable: false),
  };
}

final class AppBlockProjectionSnapshot {
  AppBlockProjectionSnapshot(Iterable<AppBlockGateProjection> projections)
    : projections = List<AppBlockGateProjection>.unmodifiable(projections);

  final List<AppBlockGateProjection> projections;
  List<AppBlockGateProjection> get blocked => projections
      .where((projection) => projection.blocked)
      .toList(growable: false);

  Map<String, Object?> toMap() => <String, Object?>{
    'version': 1,
    'projections': projections
        .map((projection) => projection.toMap())
        .toList(growable: false),
  };
}
