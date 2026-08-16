import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/platform/notification_gateway.dart';
import 'package:habiter/core/time/local_date.dart';
import 'package:habiter/features/reminders/application/notification_id_registry.dart';
import 'package:habiter/features/reminders/application/reminder_reconciler.dart';
import 'package:habiter/features/reminders/domain/reminder_payload.dart';
import 'package:habiter/features/reminders/domain/reminder_plan.dart';

import '../../support/fakes/in_memory_key_value_store.dart';
import '../../support/fakes/recording_notification_gateway.dart';

void main() {
  test('ids remain stable across registry instances and recreation', () async {
    final store = InMemoryKeyValueStore();
    final first = NotificationIdRegistry(store);
    final id = await first.idFor('habit:one');

    expect(await NotificationIdRegistry(store).idFor('habit:one'), id);
    await first.release('habit:one');
    expect(await NotificationIdRegistry(store).idFor('habit:one'), id);
    expect(id, inInclusiveRange(1, 0x7fffffff));
  });

  test('typed payload roundtrips and rejects future schemas', () {
    final payload = ReminderPayload(
      habitId: 'habit',
      occurrence: LocalDate(2026, 8, 14),
      notificationKey: 'habit@2026-08-14:normal:0',
      kind: PlannedReminderKind.normal,
      reason: const ReminderReason(
        code: ReminderReasonCode.habitLearnedPeak,
        sourceProfileId: 'habit:habit',
        factors: <String, double>{'availability': 0.8},
      ),
      snoozeDuration: const Duration(minutes: 45),
      action: 'complete',
    );

    expect(
      ReminderPayload.fromMap(payload.toMap()).occurrence,
      LocalDate(2026, 8, 14),
    );
    expect(
      ReminderPayload.fromMap(payload.toMap()).reason.code,
      ReminderReasonCode.habitLearnedPeak,
    );
    expect(
      ReminderPayload.fromMap(payload.toMap()).snoozeDuration,
      const Duration(minutes: 45),
    );
    final legacyV2 =
        Map<String, Object?>.from(
            jsonDecode(jsonEncode(payload.toMap())) as Map,
          )
          ..['v'] = 2
          ..remove('snoozeDurationMinutes');
    expect(
      ReminderPayload.fromMap(legacyV2).snoozeDuration,
      const Duration(minutes: 30),
    );
    expect(
      () => ReminderPayload.fromMap(<String, Object?>{
        ...payload.toMap(),
        'v': 99,
      }),
      throwsFormatException,
    );
  });

  test('reconciliation removes unknown pending ids and reports gaps', () async {
    final store = InMemoryKeyValueStore();
    final registry = NotificationIdRegistry(store);
    final knownId = await registry.idFor('habit:one');
    await registry.idFor('habit:missing');
    final gateway = RecordingNotificationGateway();
    await gateway.schedule(
      NotificationRequest(
        id: knownId,
        scheduledFor: DateTime.utc(2026, 8, 15),
        title: 'Habit',
        body: 'Reminder',
      ),
    );
    await gateway.schedule(
      NotificationRequest(
        id: 42,
        scheduledFor: DateTime.utc(2026, 8, 15),
        title: 'Unknown',
        body: 'Unknown',
      ),
    );

    final result = await ReminderReconciler(
      registry: registry,
      gateway: gateway,
    ).reconcile();

    expect(result.cancelledUnknownIds, <int>[42]);
    expect(result.missingLogicalKeys, <String>['habit:missing']);
    expect((await gateway.pending()).map((request) => request.id), <int>[
      knownId,
    ]);
  });
}
