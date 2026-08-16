import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/persistence/storage_envelope.dart';
import '../../../core/time/local_date.dart';
import '../../../models/habit.dart';
import '../../../models/locked_app.dart';
import '../../today/application/today_query.dart';
import '../domain/widget_snapshot.dart';

final class WidgetAppLockStateResolver {
  const WidgetAppLockStateResolver(this._store);

  static const configKey = 'habiter_app_lock_config';

  final KeyValueStore _store;

  Future<WidgetAppLockState?> resolve({
    required LocalDate date,
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
  }) async {
    final config = await _readConfig();
    if (config == null || !config.isEnabled) return null;
    final today = TodayQuery.forDate(
      date: date,
      habits: habits,
      entries: entries,
    );
    final required = (config.requiredHabitIds ?? const <String>[]).toSet();
    final incomplete = today.pending
        .where(
          (habit) =>
              config.lockUntilAllHabitsComplete || required.contains(habit.id),
        )
        .map((habit) => habit.name)
        .toList(growable: false);
    return WidgetAppLockState(
      complete: incomplete.isEmpty,
      incompleteHabitNames: incomplete,
    );
  }

  Future<AppLockConfig?> _readConfig() async {
    Object? value;
    final envelopeValue = await _store.read(StorageEnvelope.storageKey);
    if (envelopeValue is String) {
      try {
        value = StorageEnvelope.fromJson(envelopeValue).data[configKey];
      } on FormatException {
        // Fall through to the legacy key during recovery.
      }
    }
    value ??= await _store.read(configKey);
    if (value == null) return null;
    try {
      final decoded = value is String ? jsonDecode(value) : value;
      if (decoded is! Map) return null;
      return AppLockConfig.fromMap(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    }
  }
}
