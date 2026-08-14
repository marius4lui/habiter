import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/reminder_action_inbox.dart';

import '../../support/fakes/fake_clock.dart';
import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test('background-style writes survive restart and drain at startup', () async {
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
  });

  test('duplicate actions are idempotent in foreground and background', () async {
    final inbox = ReminderActionInbox(InMemoryKeyValueStore());
    final action = _action('duplicate', '2026-08-14');
    await Future.wait(<Future<void>>[inbox.enqueue(action), inbox.enqueue(action)]);

    expect(await inbox.pending(), hasLength(1));
  });

  test('stale occurrences are acknowledged without completing history', () async {
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
  });

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
}

ReminderActionRecord _action(String id, String date) => ReminderActionRecord(
  id: id,
  habitId: 'habit',
  occurrence: LocalDate.parse(date),
  receivedAt: DateTime.utc(2026, 8, 14),
);
