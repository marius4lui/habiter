import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../application/reminder_diagnostics.dart';

class ReminderDiagnosticsPanel extends StatelessWidget {
  const ReminderDiagnosticsPanel({
    super.key,
    required this.snapshot,
    required this.onSendTest,
    required this.onReschedule,
  });

  final ReminderDiagnosticSnapshot snapshot;
  final Future<void> Function() onSendTest;
  final Future<void> Function() onReschedule;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.permission.canSchedule
                ? context.l10n.reminderPermissionGranted
                : context.l10n.reminderPermissionMissing,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.pendingReminders(snapshot.pending.length),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (snapshot.pending.isEmpty)
            Text(context.l10n.noPendingReminders)
          else
            for (final item in snapshot.pending)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: Text('#${item.id} · ${item.title}'),
                subtitle: Text(
                  item.scheduledFor?.toLocal().toIso8601String() ??
                      context.l10n.osManagedReminderTime,
                ),
              ),
          const SizedBox(height: 8),
          for (final gate in snapshot.manualGates)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $gate'),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onSendTest,
                icon: const Icon(Icons.send_outlined),
                label: Text(context.l10n.testNotification),
              ),
              FilledButton.icon(
                onPressed: onReschedule,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.rescheduleReminders),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
