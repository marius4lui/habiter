import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/platform/notification_gateway.dart';

import 'fakes/fake_clock.dart';
import 'fakes/fake_id_generator.dart';
import 'fakes/in_memory_key_value_store.dart';
import 'fakes/recording_notification_gateway.dart';
import 'fakes/recording_platform_gateway.dart';

void main() {
  group('deterministic fakes', () {
    test('clock can advance without consulting wall time', () {
      final clock = FakeClock(DateTime.utc(2026, 3, 29, 0, 30));

      clock.advance(const Duration(hours: 2));

      expect(clock.now(), DateTime.utc(2026, 3, 29, 2, 30));
    });

    test('ID generator returns a strict programmed sequence', () {
      final ids = FakeIdGenerator(<String>['habit-1', 'entry-1']);

      expect(ids.next(), 'habit-1');
      expect(ids.next(), 'entry-1');
      expect(ids.next, throwsStateError);
    });

    test('key-value store snapshots do not expose mutable state', () async {
      final store = InMemoryKeyValueStore(<String, Object?>{
        'items': <String>['one'],
      });

      final first = await store.snapshot();
      (first['items']! as List<Object?>).add('mutated');
      final second = await store.snapshot();

      expect(second['items'], <String>['one']);
      expect(store.writes, isEmpty);
    });

    test('notification fake records and reconciles pending requests', () async {
      final gateway = RecordingNotificationGateway();
      final request = NotificationRequest(
        id: 42,
        scheduledFor: DateTime.utc(2026, 8, 15, 7),
        title: 'Read',
        body: 'A small page is enough.',
        payload: const <String, String>{'habitId': 'habit-1'},
      );

      await gateway.initialize();
      await gateway.schedule(request);

      expect(gateway.initialized, isTrue);
      expect(await gateway.pending(), <NotificationRequest>[request]);
      expect(gateway.calls.map((call) => call.operation), <String>[
        'initialize',
        'schedule',
        'pending',
      ]);

      await gateway.cancel(request.id);
      expect(await gateway.pending(), isEmpty);
    });

    test('platform fake returns typed results and records arguments', () async {
      final platform = RecordingPlatformGateway(
        results: <String, Object?>{'hasPermission': true},
      );

      final result = await platform.invoke<bool>(
        'hasPermission',
        const <String, Object?>{'kind': 'overlay'},
      );

      expect(result, isTrue);
      expect(platform.calls.single.method, 'hasPermission');
      expect(platform.calls.single.arguments, <String, Object?>{
        'kind': 'overlay',
      });
    });
  });
}
