import '../../../core/platform/notification_gateway.dart';
import 'notification_id_registry.dart';

final class ReminderReconciliation {
  const ReminderReconciliation({
    required this.cancelledUnknownIds,
    required this.missingLogicalKeys,
  });

  final List<int> cancelledUnknownIds;
  final List<String> missingLogicalKeys;
}

final class ReminderReconciler {
  const ReminderReconciler({
    required NotificationIdRegistry registry,
    required NotificationGateway gateway,
  }) : _registry = registry,
       _gateway = gateway;

  final NotificationIdRegistry _registry;
  final NotificationGateway _gateway;

  Future<ReminderReconciliation> reconcile() async {
    final registered = await _registry.snapshot();
    final pending = await _gateway.pending();
    final knownIds = registered.values.toSet();
    final pendingIds = pending.map((request) => request.id).toSet();
    final unknown = pendingIds.difference(knownIds).toList()..sort();
    for (final id in unknown) {
      await _gateway.cancel(id);
    }
    final missing = registered.entries
        .where((entry) => !pendingIds.contains(entry.value))
        .map((entry) => entry.key)
        .toList()
      ..sort();
    return ReminderReconciliation(
      cancelledUnknownIds: List<int>.unmodifiable(unknown),
      missingLogicalKeys: List<String>.unmodifiable(missing),
    );
  }
}
