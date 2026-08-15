import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../analytics/domain/habit_metrics.dart';
import '../domain/recovery_summary.dart';

class RecoveryCard extends StatelessWidget {
  const RecoveryCard({super.key, required this.metrics, required this.onHide});

  final HabitMetrics metrics;
  final Future<void> Function() onHide;

  @override
  Widget build(BuildContext context) {
    final summary = RecoverySummary.fromMetrics(metrics);
    final message = switch (summary.state) {
      RecoveryState.newStart => context.l10n.recoveryNewStart,
      RecoveryState.gentleReturn => context.l10n.recoveryGentleReturn,
      RecoveryState.rebuilding => context.l10n.recoveryRebuilding,
      RecoveryState.steady => context.l10n.recoverySteady,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.recoveryTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.recoveryHide,
                  onPressed: onHide,
                  icon: const Icon(Icons.visibility_off_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            Text(
              context.l10n.recoveryFormula(
                summary.completed,
                summary.scheduled,
                summary.score,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
