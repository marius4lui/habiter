import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../habits/application/habit_repository.dart';
import '../data/widget_snapshot_mapper.dart';
import '../domain/widget_bridge.dart';
import '../domain/widget_snapshot.dart';

final class WidgetSyncController {
  const WidgetSyncController({
    required HabitRepository repository,
    required WidgetBridge bridge,
    required Clock clock,
    this.mapper = const WidgetSnapshotMapper(),
  }) : _repository = repository,
       _bridge = bridge,
       _clock = clock;

  final HabitRepository _repository;
  final WidgetBridge _bridge;
  final Clock _clock;
  final WidgetSnapshotMapper mapper;

  Future<WidgetSnapshot> synchronize({
    required String locale,
    WidgetLastCompletion? lastCompletion,
  }) async {
    final now = _clock.now();
    final snapshot = await _repository.load();
    final widgetSnapshot = mapper.map(
      generatedAt: now,
      date: LocalDate.fromDateTime(now),
      locale: locale,
      habits: snapshot.habits,
      entries: snapshot.entries,
      lastCompletion: lastCompletion,
    );
    await _bridge.publish(widgetSnapshot);
    return widgetSnapshot;
  }
}
