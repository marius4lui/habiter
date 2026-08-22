import '../../../core/platform/notification_gateway.dart';
import '../../runtime/domain/background_runtime_gateway.dart';
import '../../runtime/domain/runtime_diagnostics.dart';
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
    this.runtime,
    this.runtimeMessage,
  }) : pending = List<ReminderDiagnosticItem>.unmodifiable(pending),
       manualGates = List<String>.unmodifiable(manualGates);

  final ReminderPermissionSnapshot permission;
  final List<ReminderDiagnosticItem> pending;
  final List<String> manualGates;
  final RuntimeDiagnostics? runtime;
  final String? runtimeMessage;
}

final class ReminderDiagnosticsController {
  const ReminderDiagnosticsController({
    required NotificationGateway notifications,
    required ReminderPermissionGateway permissions,
    required BackgroundRuntimeGateway runtime,
  }) : _notifications = notifications,
       _permissions = permissions,
       _runtime = runtime;

  final NotificationGateway _notifications;
  final ReminderPermissionGateway _permissions;
  final BackgroundRuntimeGateway _runtime;

  Future<ReminderDiagnosticSnapshot> load() async {
    final permission = await _permissions.current();
    final pending = await _notifications.pending();
    final runtimeResult = await _runtime.diagnostics();
    final runtime = switch (runtimeResult) {
      BackgroundRuntimeSuccess<RuntimeDiagnostics>(:final value) => value,
      BackgroundRuntimeFailure<RuntimeDiagnostics>() => null,
    };
    final runtimeMessage = switch (runtimeResult) {
      BackgroundRuntimeSuccess<RuntimeDiagnostics>() => null,
      BackgroundRuntimeFailure<RuntimeDiagnostics>(:final safeMessage) =>
        safeMessage,
    };
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
      runtime: runtime,
      runtimeMessage: runtimeMessage,
    );
  }
}
