import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/platform/notification_gateway.dart';
import 'package:habiter/features/reminders/application/reminder_diagnostics.dart';
import 'package:habiter/features/reminders/application/reminder_permission_controller.dart';

import '../../support/fakes/recording_notification_gateway.dart';

void main() {
  test('diagnostics expose safe ids and times without payload values', () async {
    final notifications = RecordingNotificationGateway();
    await notifications.schedule(
      NotificationRequest(
        id: 17,
        scheduledFor: DateTime.utc(2026, 8, 15, 9),
        title: 'Walk',
        body: 'Private body',
        payload: const <String, String>{'secret': 'must-not-leak'},
      ),
    );
    final snapshot = await ReminderDiagnosticsController(
      notifications: notifications,
      permissions: _GrantedPermissions(),
    ).load();

    expect(snapshot.pending.single.id, 17);
    expect(snapshot.pending.single.scheduledFor, DateTime.utc(2026, 8, 15, 9));
    expect(snapshot.pending.single.title, 'Walk');
    expect(snapshot.toString(), isNot(contains('must-not-leak')));
    expect(snapshot.manualGates, hasLength(2));
  });
}

final class _GrantedPermissions implements ReminderPermissionGateway {
  @override
  Future<ReminderPermissionSnapshot> current() async =>
      const ReminderPermissionSnapshot(
        notifications: ReminderPermissionStatus.granted,
        exactAlarmAvailable: false,
      );

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<ReminderPermissionStatus> requestNotifications() async =>
      ReminderPermissionStatus.granted;
}
