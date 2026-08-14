import 'dart:async';
import 'dart:collection';

import '../../../models/habit.dart';

abstract interface class HabitRepository {
  Future<HabitRepositorySnapshot> load();

  Future<void> transact(
    FutureOr<void> Function(HabitRepositoryDraft draft) mutation,
  );
}

final class HabitRepositorySnapshot {
  HabitRepositorySnapshot({
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
  }) : habits = UnmodifiableListView<Habit>(habits.toList()),
       entries = UnmodifiableListView<HabitEntry>(entries.toList());

  final List<Habit> habits;
  final List<HabitEntry> entries;
}

final class HabitRepositoryDraft {
  HabitRepositoryDraft({
    required Iterable<Habit> habits,
    required Iterable<HabitEntry> entries,
  }) : habits = habits.toList(),
       entries = entries.toList();

  final List<Habit> habits;
  final List<HabitEntry> entries;

  void upsertHabit(Habit habit) {
    habits.removeWhere((existing) => existing.id == habit.id);
    habits.insert(0, habit);
  }

  void deleteHabit(String habitId) {
    habits.removeWhere((habit) => habit.id == habitId);
    entries.removeWhere((entry) => entry.habitId == habitId);
  }

  void upsertEntry(HabitEntry entry) {
    entries.removeWhere(
      (existing) =>
          existing.habitId == entry.habitId && existing.date == entry.date,
    );
    entries.add(entry);
  }

  void removeEntry(String habitId, String date) {
    entries.removeWhere(
      (entry) => entry.habitId == habitId && entry.date == date,
    );
  }
}

final class HabitRepositoryException implements Exception {
  const HabitRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'HabitRepositoryException: $message';
}
