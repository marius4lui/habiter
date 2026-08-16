import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/reminder_action_inbox.dart';
import 'package:habiter/features/reminders/domain/reminder_action.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test(
    'background-style writes survive restart and drain at startup',
    () async {
      final store = InMemoryKeyValueStore();
      final inbox = ReminderActionInbox(store);
      await inbox.enqueue(_action('one', '2026-08-14'));

      final completed = <String>[];
      final processor = ReminderActionProcessor(
        inbox: ReminderActionInbox(store),
        clock: FakeClock(DateTime.utc(2026, 8, 14, 12)),
        complete: (habitId, date) async => completed.add('$habitId@$date'),
      );

      expect(await processor.drain(), 1);
      expect(completed, <String>['habit@2026-08-14']);
      expect(await inbox.pending(), isEmpty);
    },
  );

  test(
    'duplicate actions are idempotent in foreground and background',
    () async {
      final inbox = ReminderActionInbox(InMemoryKeyValueStore());
      final action = _action('duplicate', '2026-08-14');
      await Future.wait(<Future<void>>[
        inbox.enqueue(action),
        inbox.enqueue(action),
      ]);

      expect(await inbox.pending(), hasLength(1));
    },
  );

  test(
    'stale occurrences are acknowledged without completing history',
    () async {
      final inbox = ReminderActionInbox(InMemoryKeyValueStore());
      await inbox.enqueue(_action('stale', '2026-08-13'));
      var completions = 0;

      final processed = await ReminderActionProcessor(
        inbox: inbox,
        clock: FakeClock(DateTime.utc(2026, 8, 14)),
        complete: (_, _) async => completions++,
      ).drain();

      expect(processed, 0);
      expect(completions, 0);
      expect(await inbox.pending(), isEmpty);
    },
  );

  test('failed processing remains durable for retry', () async {
    final inbox = ReminderActionInbox(InMemoryKeyValueStore());
    await inbox.enqueue(_action('retry', '2026-08-14'));

    await expectLater(
      ReminderActionProcessor(
        inbox: inbox,
        clock: FakeClock(DateTime.utc(2026, 8, 14)),
        complete: (_, _) => throw StateError('write failed'),
      ).drain(),
      throwsStateError,
    );
    expect(await inbox.pending(), hasLength(1));
  });

  test(
    'feedback and snooze actions are typed and processed idempotently',
    () async {
      final inbox = ReminderActionInbox(InMemoryKeyValueStore());
      await inbox.enqueue(
        _action(
          'feedback',
          '2026-08-14',
          kind: ReminderActionKind.feasibilityBad,
        ),
      );
      await inbox.enqueue(
        _action('snooze', '2026-08-14', kind: ReminderActionKind.snooze),
      );
      final handled = <String>[];
      final marked = <String>{};
      final processor = ReminderActionProcessor(
        inbox: inbox,
        clock: FakeClock(DateTime.utc(2026, 8, 14)),
        complete: (_, _) async {},
        recordFeasibility: (action, rating) async {
          handled.add('${action.id}:${rating.name}');
        },
        snooze: (action) async => handled.add('${action.id}:snooze'),
        isProcessed: (id) async => marked.contains(id),
        markProcessed: (id) async => marked.add(id),
      );

      expect(await processor.drain(), 2);
      expect(handled, <String>['feedback:bad', 'snooze:snooze']);
      await inbox.enqueue(
        _action(
          'feedback',
          '2026-08-14',
          kind: ReminderActionKind.feasibilityBad,
        ),
      );
      expect(await processor.drain(), 0);
      expect(handled, hasLength(2));
    },
  );
}

ReminderActionRecord _action(
  String id,
  String date, {
  ReminderActionKind kind = ReminderActionKind.complete,
}) => ReminderActionRecord(
  id: id,
  habitId: 'habit',
  occurrence: LocalDate.parse(date),
  receivedAt: DateTime.utc(2026, 8, 14),
  notificationKey: 'habit@$date',
  kind: kind,
);
