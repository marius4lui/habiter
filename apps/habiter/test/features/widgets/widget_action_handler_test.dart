import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/widgets/application/widget_action_handler.dart';
import 'package:habiter/features/widgets/application/widget_sync_controller.dart';
import 'package:habiter/features/widgets/domain/widget_action.dart';
import 'package:habiter/features/widgets/domain/widget_bridge.dart';
import 'package:habiter/features/widgets/domain/widget_snapshot.dart';
import 'package:habiter/models/habit.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/fake_id_generator.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test(
    'cold action reuses completion semantics and publishes a snapshot',
    () async {
      final store = InMemoryKeyValueStore();
      final repository = KeyValueHabitRepository(store);
      final clock = FakeClock(DateTime(2026, 8, 16, 12));
      await repository.transact(
        (draft) => draft.upsertHabit(
          Habit(
            id: 'habit-1',
            name: 'Training',
            color: '#C45B42',
            icon: '🏋️',
            frequency: HabitFrequency.daily,
            targetCount: 1,
            category: 'Fitness',
            createdAt: DateTime(2026, 8, 1),
            isActive: true,
          ),
        ),
      );
      final bridge = _RecordingWidgetBridge();
      final sync = WidgetSyncController(
        repository: repository,
        bridge: bridge,
        clock: clock,
      );
      final handler = WidgetActionHandler(
        repository: repository,
        actionStore: store,
        ids: FakeIdGenerator(const <String>['entry-1']),
        clock: clock,
        sync: sync,
      );
      final action = WidgetAction.completeHabit(
        habitId: 'habit-1',
        localDate: '2026-08-16',
        actionId: 'tap-1',
      );

      final first = await handler.handle(action, locale: 'en');
      final replay = await handler.handle(action, locale: 'en');

      final repositorySnapshot = await repository.load();
      expect(first.status, WidgetActionStatus.completed);
      expect(replay.status, WidgetActionStatus.alreadyProcessed);
      expect(repositorySnapshot.entries, hasLength(1));
      expect(repositorySnapshot.entries.single.completed, isTrue);
      expect(bridge.published, hasLength(1));
      expect(bridge.published.single.allComplete, isTrue);
      expect(bridge.published.single.lastCompletion?.actionId, 'tap-1');
      final undo = WidgetAction.undoCompletion(
        habitId: 'habit-1',
        localDate: '2026-08-16',
        actionId: 'undo-tap-1',
        sourceActionId: 'tap-1',
      );
      final undone = await handler.handle(undo, locale: 'en');
      final undoReplay = await handler.handle(undo, locale: 'en');
      final afterUndo = await repository.load();

      expect(undone.status, WidgetActionStatus.completed);
      expect(undoReplay.status, WidgetActionStatus.alreadyProcessed);
      expect(afterUndo.entries, isEmpty);
      expect(bridge.published, hasLength(2));
      expect(bridge.published.last.lastCompletion, isNull);
    },
  );
}

final class _RecordingWidgetBridge implements WidgetBridge {
  final List<WidgetSnapshot> published = <WidgetSnapshot>[];

  @override
  Future<bool> hasInstalledWidgets() async => true;

  @override
  Future<bool> isPinningSupported() async => true;

  @override
  Future<void> publish(WidgetSnapshot snapshot) async =>
      published.add(snapshot);

  @override
  Future<WidgetPinResult> requestPin() async => WidgetPinResult.pinned;

  @override
  Future<void> updateAll() async {}
}
