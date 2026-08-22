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
            context.l10n.backgroundRuntimeDiagnostics,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (snapshot.runtime case final runtime?) ...[
            _DiagnosticRow(
              label: context.l10n.runtimeAdaptiveReminders,
              value: runtime.features.remindersEnabled
                  ? context.l10n.runtimeStatusOn
                  : context.l10n.runtimeStatusOff,
            ),
            _DiagnosticRow(
              label: context.l10n.runtimeAppBlock,
              value: runtime.features.appBlockEnabled
                  ? context.l10n.runtimeStatusOn
                  : context.l10n.runtimeStatusOff,
            ),
            _DiagnosticRow(
              label: context.l10n.runtimeStarted,
              value: _format(context, runtime.runtimeStartedAt),
            ),
            _DiagnosticRow(
              label: context.l10n.runtimeHeartbeat,
              value: _format(context, runtime.lastHeartbeatAt),
            ),
            _DiagnosticRow(
              label: context.l10n.runtimeReminderEvaluation,
              value: _format(context, runtime.lastReminderEvaluationAt),
            ),
            _DiagnosticRow(
              label: context.l10n.runtimeNextEvaluation,
              value: _format(context, runtime.nextReminderEvaluationAt),
            ),
            _DiagnosticRow(
              label: context.l10n.runtimeNotificationDispatch,
              value: _format(context, runtime.lastNotificationDispatchAt),
            ),
            _DiagnosticRow(
              label: context.l10n.runtimeStartReason,
              value: runtime.lastStartReason ?? context.l10n.runtimeNotRecorded,
            ),
          ] else
            Text(snapshot.runtimeMessage ?? context.l10n.runtimeUnavailable),
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

  String _format(BuildContext context, DateTime? value) =>
      value?.toLocal().toIso8601String() ?? context.l10n.runtimeNotRecorded;
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text('$label: $value'),
  );
}
