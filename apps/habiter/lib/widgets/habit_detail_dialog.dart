import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/design_system/components.dart';
import '../core/design_system/tokens.dart';
import '../features/habits/domain/habit_source.dart';
import '../features/habits/presentation/templates/habit_template.dart';
import '../l10n/l10n.dart';
import '../models/habit.dart';

class HabitDetailDialog extends StatelessWidget {
  const HabitDetailDialog({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.onComplete,
    required this.onArchive,
    required this.onPause,
    required this.onEdit,
  });

  final Habit habit;
  final bool isCompleted;
  final VoidCallback onComplete;
  final VoidCallback onArchive;
  final VoidCallback onPause;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = habit.color.asHabiterColor;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HabiterRadius.prominent),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HabiterSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(
                        HabiterRadius.control,
                      ),
                    ),
                    child: Text(
                      habit.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: HabiterSpace.sm2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: HabiterSpace.xs),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Chip(
                              label: Text(
                                localizedHabitCategory(
                                  context.l10n,
                                  habit.category,
                                ),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            if (habit.source.kind ==
                                HabitSourceKind.classlyCompatible)
                              const Chip(
                                label: Text('Classly'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (habit.description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: HabiterSpace.lg),
                Text(habit.description!, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: HabiterSpace.lg),
              HabiterSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _DetailTile(
                      icon: Icons.repeat_rounded,
                      label: context.l10n.frequency,
                      value: _frequency(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    _DetailTile(
                      icon: Icons.flag_outlined,
                      label: context.l10n.goal,
                      value: habit.frequency == HabitFrequency.weekly
                          ? context.l10n.perWeek(habit.targetCount)
                          : context.l10n.perDayTarget(habit.targetCount),
                    ),
                    const Divider(height: 1, indent: 56),
                    _DetailTile(
                      icon: Icons.calendar_today_outlined,
                      label: context.l10n.createdAt,
                      value: DateFormat.yMMMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(habit.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HabiterSpace.md),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(HabiterSpace.md),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(HabiterRadius.control),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                      ),
                      const SizedBox(width: HabiterSpace.sm),
                      Expanded(
                        child: Text(
                          isCompleted
                              ? context.l10n.todayDone
                              : context.l10n.notCompleted,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: HabiterSpace.lg),
              FilledButton.icon(
                onPressed: () {
                  onComplete();
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  isCompleted ? Icons.undo_rounded : Icons.check_rounded,
                ),
                label: Text(
                  isCompleted
                      ? context.l10n.undoComplete
                      : context.l10n.markAsComplete,
                ),
              ),
              const SizedBox(height: HabiterSpace.sm),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onEdit();
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.edit),
              ),
              const SizedBox(height: HabiterSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        onPause();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.pause_circle_outline_rounded),
                      label: Text(context.l10n.pauseHabit),
                    ),
                  ),
                  const SizedBox(width: HabiterSpace.sm),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        onArchive();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.archive_outlined),
                      label: Text(context.l10n.archive),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _frequency(BuildContext context) => switch (habit.frequency) {
    HabitFrequency.daily => context.l10n.daily,
    HabitFrequency.weekly => context.l10n.perWeek(habit.targetCount),
    HabitFrequency.custom => context.l10n.custom,
  };
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(label), subtitle: Text(value));
}
