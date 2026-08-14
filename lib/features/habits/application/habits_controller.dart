import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/application/feature_status.dart';
import '../../../core/ids/id_generator.dart';
import '../../../core/time/clock.dart';
import '../../../models/habit.dart';
import 'habit_repository.dart';

final class HabitsState {
  HabitsState({
    required this.status,
    Iterable<Habit> habits = const <Habit>[],
    this.diagnostic,
  }) : habits = UnmodifiableListView<Habit>(habits.toList());

  const HabitsState.initial()
    : status = FeatureStatus.initial,
      habits = const <Habit>[],
      diagnostic = null;

  final FeatureStatus status;
  final List<Habit> habits;
  final String? diagnostic;
}

final class HabitsController extends ChangeNotifier {
  HabitsController({
    required HabitRepository repository,
    required IdGenerator ids,
    required Clock clock,
  }) : _repository = repository,
       _ids = ids,
       _clock = clock;

  final HabitRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;
  HabitsState _state = const HabitsState.initial();

  HabitsState get state => _state;

  Future<void> load() async {
    _emit(HabitsState(status: FeatureStatus.loading, habits: _state.habits));
    try {
      final snapshot = await _repository.load();
      _emit(
        HabitsState(
          status: snapshot.habits.isEmpty
              ? FeatureStatus.empty
              : FeatureStatus.ready,
          habits: snapshot.habits,
        ),
      );
    } catch (_) {
      _emit(
        HabitsState(
          status: FeatureStatus.failure,
          habits: _state.habits,
          diagnostic: 'Habits could not be loaded.',
        ),
      );
    }
  }

  Future<void> add({
    required String name,
    String? description,
    required String category,
    required HabitFrequency frequency,
    required int targetCount,
    required String color,
    required String icon,
    List<int>? customDays,
  }) async {
    final habit = Habit(
      id: _ids.next(),
      name: name,
      description: description,
      color: color,
      icon: icon,
      frequency: frequency,
      targetCount: targetCount,
      category: category,
      customDays: customDays,
      createdAt: _clock.now(),
      isActive: true,
    );
    await _repository.transact((draft) => draft.upsertHabit(habit));
    await load();
  }

  Future<void> update(Habit habit) async {
    await _repository.transact((draft) => draft.upsertHabit(habit));
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.transact((draft) => draft.deleteHabit(id));
    await load();
  }

  Future<void> archive(String id) async {
    final habit = _state.habits.where((item) => item.id == id).firstOrNull;
    if (habit == null) return;
    await update(habit.copyWith(isActive: false));
  }

  void _emit(HabitsState value) {
    _state = value;
    notifyListeners();
  }
}
