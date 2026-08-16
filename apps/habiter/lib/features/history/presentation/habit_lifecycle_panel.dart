import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/habit.dart';
import '../../../core/design_system/components.dart';

class HabitLifecyclePanel extends StatelessWidget {
  const HabitLifecyclePanel({
    super.key,
    required this.habits,
    required this.onResume,
    required this.onRestore,
    required this.onDelete,
  });

  final List<Habit> habits;
  final Future<void> Function(String habitId) onResume;
  final Future<void> Function(String habitId) onRestore;
  final Future<void> Function(String habitId) onDelete;

  @override
  Widget build(BuildContext context) {
    final managed = habits
        .where((habit) => habit.lifecycleStatus != HabitLifecycleStatus.active)
        .toList(growable: false);

    if (managed.isEmpty) return const SizedBox.shrink();

    return HabiterSurface(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('habit-lifecycle-panel'),
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(context.l10n.pausedArchivedCount(managed.length)),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          const Divider(height: 1),
          for (final habit in managed)
            _LifecycleHabitTile(
              habit: habit,
              onActivate: () async {
                if (habit.lifecycleStatus == HabitLifecycleStatus.paused) {
                  await onResume(habit.id);
                } else {
                  await onRestore(habit.id);
                }
              },
              onDelete: () => _confirmDelete(context, habit),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteHabit),
        content: Text(context.l10n.deleteHabitConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDelete(habit.id);
  }
}

class _LifecycleHabitTile extends StatelessWidget {
  const _LifecycleHabitTile({
    required this.habit,
    required this.onActivate,
    required this.onDelete,
  });

  final Habit habit;
  final Future<void> Function() onActivate;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final paused = habit.lifecycleStatus == HabitLifecycleStatus.paused;
    return ListTile(
      key: ValueKey('lifecycle-${habit.id}'),
      leading: Text(habit.icon, style: const TextStyle(fontSize: 24)),
      title: Text(habit.name),
      subtitle: Text(
        paused ? context.l10n.habitPaused : context.l10n.habitArchived,
      ),
      isThreeLine: MediaQuery.textScalerOf(context).scale(16) > 24,
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: paused
                ? context.l10n.resumeHabit
                : context.l10n.restoreHabit,
            onPressed: onActivate,
            icon: Icon(paused ? Icons.play_arrow : Icons.unarchive_outlined),
          ),
          IconButton(
            tooltip: context.l10n.delete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
