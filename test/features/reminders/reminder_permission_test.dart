import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/reminders/application/reminder_permission_controller.dart';

void main() {
  test('permission is requested only after intent and never loops', () async {
    final gateway = _PermissionGateway(ReminderPermissionStatus.denied);
    final controller = ReminderPermissionController(gateway);

    await controller.refresh();
    expect(gateway.requests, 0);
    await controller.requestAfterUserIntent();
    await controller.requestAfterUserIntent();
    expect(gateway.requests, 1);
  });

  test(
    'granted, permanently denied and unsupported states do not prompt',
    () async {
      for (final status in <ReminderPermissionStatus>[
        ReminderPermissionStatus.granted,
        ReminderPermissionStatus.permanentlyDenied,
        ReminderPermissionStatus.unsupported,
      ]) {
        final gateway = _PermissionGateway(status);
        final controller = ReminderPermissionController(gateway);
        expect(
          (await controller.requestAfterUserIntent()).notifications,
          status,
        );
        expect(gateway.requests, 0);
      }
    },
  );

  test(
    'exact alarm capability is informative and never blocks reminders',
    () async {
      final gateway = _PermissionGateway(
        ReminderPermissionStatus.granted,
        exactAlarmAvailable: false,
      );
      final state = await ReminderPermissionController(gateway).refresh();

      expect(state.canSchedule, isTrue);
      expect(state.exactAlarmAvailable, isFalse);
    },
  );
}

final class _PermissionGateway implements ReminderPermissionGateway {
  _PermissionGateway(this.status, {this.exactAlarmAvailable = false});

  ReminderPermissionStatus status;
  final bool exactAlarmAvailable;
  int requests = 0;

  @override
  Future<ReminderPermissionSnapshot> current() async =>
      ReminderPermissionSnapshot(
        notifications: status,
        exactAlarmAvailable: exactAlarmAvailable,
      );

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<ReminderPermissionStatus> requestNotifications() async {
    requests++;
    return status;
  }
}
