import '../../../core/platform/notification_gateway.dart';
import 'reminder_permission_controller.dart';

final class ReminderDiagnosticItem {
  const ReminderDiagnosticItem({
    required this.id,
    required this.title,
    this.scheduledFor,
  });

  final int id;
  final String title;
  final DateTime? scheduledFor;
}

final class ReminderDiagnosticSnapshot {
  ReminderDiagnosticSnapshot({
    required this.permission,
    required Iterable<ReminderDiagnosticItem> pending,
    required Iterable<String> manualGates,
  }) : pending = List<ReminderDiagnosticItem>.unmodifiable(pending),
       manualGates = List<String>.unmodifiable(manualGates);

  final ReminderPermissionSnapshot permission;
  final List<ReminderDiagnosticItem> pending;
  final List<String> manualGates;
}

final class ReminderDiagnosticsController {
  const ReminderDiagnosticsController({
    required NotificationGateway notifications,
    required ReminderPermissionGateway permissions,
  }) : _notifications = notifications,
       _permissions = permissions;

  final NotificationGateway _notifications;
  final ReminderPermissionGateway _permissions;

  Future<ReminderDiagnosticSnapshot> load() async {
    final permission = await _permissions.current();
    final pending = await _notifications.pending();
    return ReminderDiagnosticSnapshot(
      permission: permission,
      pending: pending.map(
        (request) => ReminderDiagnosticItem(
          id: request.id,
          title: request.title,
          scheduledFor: request.scheduledFor,
        ),
      ),
      manualGates: const <String>[
        'Delivery timing remains subject to device battery and OEM policy.',
        'Background actions require a real-device process-state check.',
      ],
    );
  }
}
