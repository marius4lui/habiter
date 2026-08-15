import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/application/feature_status.dart';
import '../../../models/habit.dart';
import '../../habits/application/habit_repository.dart';

final class HistoryState {
  HistoryState({
    required this.status,
    Iterable<HabitEntry> entries = const <HabitEntry>[],
    this.diagnostic,
  }) : entries = UnmodifiableListView<HabitEntry>(entries.toList());

  const HistoryState.initial()
    : status = FeatureStatus.initial,
      entries = const <HabitEntry>[],
      diagnostic = null;

  final FeatureStatus status;
  final List<HabitEntry> entries;
  final String? diagnostic;
}

final class HistoryController extends ChangeNotifier {
  HistoryController(this._repository);

  final HabitRepository _repository;
  HistoryState _state = const HistoryState.initial();

  HistoryState get state => _state;

  Future<void> load() async {
    _emit(HistoryState(status: FeatureStatus.loading, entries: _state.entries));
    try {
      final snapshot = await _repository.load();
      _emit(
        HistoryState(
          status: snapshot.entries.isEmpty
              ? FeatureStatus.empty
              : FeatureStatus.ready,
          entries: snapshot.entries,
        ),
      );
    } catch (_) {
      _emit(
        HistoryState(
          status: FeatureStatus.failure,
          entries: _state.entries,
          diagnostic: 'History could not be loaded.',
        ),
      );
    }
  }

  void _emit(HistoryState value) {
    _state = value;
    notifyListeners();
  }
}
