import 'dart:convert';

import '../../habits/application/habit_repository.dart';
import '../../../models/habit.dart';

enum ImportCollisionPolicy { keepExisting, replaceExisting }

final class ImportPreview {
  const ImportPreview({
    required this.habits,
    required this.entries,
    required this.collisions,
  });

  final int habits;
  final int entries;
  final int collisions;
}

final class DataPortabilityService {
  const DataPortabilityService(this._repository);
  static const schemaVersion = 1;
  final HabitRepository _repository;

  Future<String> exportJson({Map<String, Object?> settings = const {}}) async {
    final snapshot = await _repository.load();
    final safeSettings = Map<String, Object?>.from(settings)
      ..removeWhere((key, _) => _looksSecret(key));
    return jsonEncode(<String, Object?>{
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'habits': snapshot.habits.map((habit) => habit.toMap()).toList(),
      'entries': snapshot.entries.map((entry) => entry.toMap()).toList(),
      'settings': safeSettings,
    });
  }

  Future<ImportPreview> preview(String input) async {
    final decoded = _decode(input);
    final current = await _repository.load();
    final ids = current.habits.map((habit) => habit.id).toSet();
    return ImportPreview(
      habits: decoded.habits.length,
      entries: decoded.entries.length,
      collisions: decoded.habits
          .where((habit) => ids.contains(habit.id))
          .length,
    );
  }

  Future<String> importJson(
    String input, {
    ImportCollisionPolicy collisions = ImportCollisionPolicy.keepExisting,
  }) async {
    final decoded = _decode(input);
    final backup = await exportJson();
    await _repository.transact((draft) {
      final existing = draft.habits.map((habit) => habit.id).toSet();
      for (final habit in decoded.habits) {
        if (existing.contains(habit.id) &&
            collisions == ImportCollisionPolicy.keepExisting) {
          continue;
        }
        draft.upsertHabit(habit);
        existing.add(habit.id);
      }
      final known = draft.habits.map((habit) => habit.id).toSet();
      for (final entry in decoded.entries) {
        if (known.contains(entry.habitId)) draft.upsertEntry(entry);
      }
    });
    return backup;
  }

  _PortableData _decode(String input) {
    final value = jsonDecode(input);
    if (value is! Map) throw const FormatException('Export must be an object.');
    final map = Map<String, Object?>.from(value);
    final version = map['schemaVersion'];
    if (version is! int || version < 1) {
      throw const FormatException('Export schema is missing or invalid.');
    }
    if (version > schemaVersion) {
      throw const FormatException('This export needs a newer Habiter version.');
    }
    final habits = _list(map['habits'], Habit.fromMap);
    final entries = _list(map['entries'], HabitEntry.fromMap);
    final ids = habits.map((habit) => habit.id).toSet();
    if (ids.length != habits.length) {
      throw const FormatException('Export contains duplicate habit IDs.');
    }
    return _PortableData(habits, entries);
  }

  List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) decode) {
    if (value is! List) throw const FormatException('Export list is invalid.');
    return value
        .map((item) => decode(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  static bool _looksSecret(String key) => RegExp(
    r'(token|secret|password|api.?key|credential)',
    caseSensitive: false,
  ).hasMatch(key);
}

final class _PortableData {
  const _PortableData(this.habits, this.entries);
  final List<Habit> habits;
  final List<HabitEntry> entries;
}
