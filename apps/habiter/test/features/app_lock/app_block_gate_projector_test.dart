import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/app_lock/application/app_block_gate_projector.dart';
import 'package:habiter/features/app_lock/domain/app_block_config.dart';
import 'package:habiter/features/app_lock/domain/app_block_rule.dart';
import 'package:habiter/features/app_lock/domain/app_lock_gateway.dart';
import 'package:habiter/models/habit.dart';

void main() {
  const projector = AppBlockGateProjector();
  const ready = AppLockPermissionSnapshot(usageAccess: true, overlay: true);
  final today = LocalDate(2026, 8, 19);
  final read = _habit('read', 'Read');
  final move = _habit('move', 'Move');
  final config = AppBlockConfig(
    isEnabled: true,
    rules: <AppBlockRule>[
      AppBlockRule(
        packageName: 'social.example',
        appName: 'Social',
        requirement: HabitRequirement(<String>['read']),
      ),
      AppBlockRule(
        packageName: 'video.example',
        appName: 'Video',
        requirement: HabitRequirement(<String>['move']),
      ),
    ],
  );

  test('each package receives only its own blockers', () {
    final snapshot = projector.project(
      config: config,
      permissions: ready,
      date: today,
      habits: <Habit>[read, move],
      entries: <HabitEntry>[_entry('read', today)],
    );

    expect(snapshot.projections, hasLength(2));
    expect(
      snapshot.projections
          .singleWhere((value) => value.packageName == 'social.example')
          .blocked,
      isFalse,
    );
    expect(snapshot.blocked.single.blockers.single.habitId, 'move');
  });

  test('permission revocation fails open without stale projections', () {
    final snapshot = projector.project(
      config: config,
      permissions: const AppLockPermissionSnapshot(
        usageAccess: true,
        overlay: false,
      ),
      date: today,
      habits: <Habit>[read, move],
      entries: const <HabitEntry>[],
    );
    expect(snapshot.projections, isEmpty);
  });

  test('deleted habits and uninstalled packages fail open', () {
    final snapshot = projector.project(
      config: config,
      permissions: ready,
      date: today,
      habits: <Habit>[read],
      entries: const <HabitEntry>[],
      installedPackages: <String>{'video.example'},
    );
    expect(snapshot.projections.single.packageName, 'video.example');
    expect(snapshot.projections.single.blocked, isFalse);
  });

  test('fresh completion data immediately refreshes the projection', () {
    final pending = projector.project(
      config: config,
      permissions: ready,
      date: today,
      habits: <Habit>[read, move],
      entries: const <HabitEntry>[],
    );
    final complete = projector.project(
      config: config,
      permissions: ready,
      date: today,
      habits: <Habit>[read, move],
      entries: <HabitEntry>[_entry('read', today), _entry('move', today)],
    );
    expect(pending.blocked, hasLength(2));
    expect(complete.blocked, isEmpty);
  });
}

Habit _habit(String id, String name) => Habit(
  id: id,
  name: name,
  color: '#000000',
  icon: 'x',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Test',
  createdAt: DateTime(2026, 1, 1),
  isActive: true,
);

HabitEntry _entry(String habitId, LocalDate date) => HabitEntry(
  id: '$habitId-$date',
  habitId: habitId,
  date: date.toString(),
  completed: true,
  count: 1,
  timestamp: DateTime(date.year, date.month, date.day),
);
