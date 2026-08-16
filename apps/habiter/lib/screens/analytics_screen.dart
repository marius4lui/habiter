import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/motion.dart';
import '../core/design_system/tokens.dart';
import '../core/time/local_date.dart';
import '../features/analytics/domain/habit_metrics.dart';
import '../features/coaching/presentation/recovery_card.dart';
import '../features/habits/domain/habit_schedule.dart';
import '../l10n/l10n.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedHabitId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits.where((habit) => habit.isActive).toList();
    final selected =
        habits.where((habit) => habit.id == _selectedHabitId).firstOrNull ??
        habits.firstOrNull;
    final completed = provider.habitEntries
        .where((entry) => entry.completed)
        .length;
    final average = habits.isEmpty
        ? 0.0
        : habits
                  .map(
                    (habit) =>
                        provider.getHabitMetrics(habit.id).completionRate,
                  )
                  .fold<double>(0, (sum, value) => sum + value) /
              habits.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        children: [
          HabiterContent(
            maxWidth: HabiterSize.wideContentMax,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HabiterPageIntro(
                  title: context.l10n.analyticsTitle,
                  subtitle: context.l10n.analyticsBody,
                ),
                const SizedBox(height: HabiterSpace.lg),
                _OverviewStrip(
                  active: habits.length,
                  completed: completed,
                  average: average,
                ),
                const SizedBox(height: HabiterSpace.lg),
                if (selected == null)
                  HabiterEmptyState(
                    icon: Icons.insights_outlined,
                    title: context.l10n.noAnalyticsTitle,
                    body: context.l10n.noAnalyticsBody,
                  )
                else ...[
                  _HabitSelector(
                    habits: habits,
                    selected: selected,
                    onChanged: (habitId) =>
                        setState(() => _selectedHabitId = habitId),
                  ),
                  const SizedBox(height: HabiterSpace.md),
                  AnimatedSwitcher(
                    duration: HabiterMotion.standard.duration(
                      reduced: context.reduceMotion,
                    ),
                    child: _RhythmPanel(
                      key: ValueKey(selected.id),
                      habit: selected,
                      entries: provider.habitEntries,
                      metrics: provider.getHabitMetrics(selected.id),
                    ),
                  ),
                  if (provider.preferences.showRecoverySupport) ...[
                    const SizedBox(height: HabiterSpace.md),
                    RecoveryCard(
                      metrics: provider.getHabitMetrics(selected.id),
                      onHide: () => provider.updatePreferences(
                        provider.preferences.copyWith(
                          showRecoverySupport: false,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({
    required this.active,
    required this.completed,
    required this.average,
  });

  final int active;
  final int completed;
  final double average;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String value, String label})>[
      (
        icon: Icons.eco_outlined,
        value: '$active',
        label: context.l10n.activeHabitsLabel,
      ),
      (
        icon: Icons.check_circle_outline,
        value: '$completed',
        label: context.l10n.totalWinsLabel,
      ),
      (
        icon: Icons.insights_rounded,
        value: '${(average * 100).round()}%',
        label: context.l10n.averageSuccessLabel,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical =
            constraints.maxWidth < 380 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4;
        return HabiterSurface(
          padding: const EdgeInsets.symmetric(
            horizontal: HabiterSpace.sm,
            vertical: HabiterSpace.xs,
          ),
          child: vertical
              ? Column(
                  children: [
                    for (final item in items) _OverviewItem(item: item),
                  ],
                )
              : Row(
                  children: [
                    for (final item in items)
                      Expanded(child: _OverviewItem(item: item)),
                  ],
                ),
        );
      },
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({required this.item});

  final ({IconData icon, String value, String label}) item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(HabiterSpace.sm),
    child: Row(
      children: [
        Icon(item.icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: HabiterSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value, style: Theme.of(context).textTheme.titleMedium),
              Text(
                item.label,
                maxLines: 2,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HabitSelector extends StatelessWidget {
  const _HabitSelector({
    required this.habits,
    required this.selected,
    required this.onChanged,
  });

  final List<Habit> habits;
  final Habit selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: selected.id,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: context.l10n.habit,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(selected.icon, style: const TextStyle(fontSize: 20)),
      ),
    ),
    items: [
      for (final habit in habits)
        DropdownMenuItem(
          value: habit.id,
          child: Text(habit.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _RhythmPanel extends StatelessWidget {
  const _RhythmPanel({
    super.key,
    required this.habit,
    required this.entries,
    required this.metrics,
  });

  final Habit habit;
  final List<HabitEntry> entries;
  final HabitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final today = LocalDate.fromDateTime(DateTime.now());
    final recent = HabitMetricCalculator.calculatePeriod(
      habit: habit,
      entries: entries,
      from: today.addDays(-29),
      through: today,
    );
    final recentHalf = HabitMetricCalculator.calculatePeriod(
      habit: habit,
      entries: entries,
      from: today.addDays(-14),
      through: today,
    );
    final priorHalf = HabitMetricCalculator.calculatePeriod(
      habit: habit,
      entries: entries,
      from: today.addDays(-29),
      through: today.addDays(-15),
    );
    final enoughHistory = metrics.scheduled >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekCard(habit: habit, entries: entries, today: today),
        const SizedBox(height: HabiterSpace.md),
        if (!enoughHistory)
          _InsufficientHistory()
        else ...[
          _ConsistencyCard(
            metrics: recent,
            prior: priorHalf,
            recent: recentHalf,
          ),
          if (metrics.weeks.length >= 3) ...[
            const SizedBox(height: HabiterSpace.xl),
            HabiterSectionHeader(title: context.l10n.historyTitle),
            const SizedBox(height: HabiterSpace.sm2),
            _HistoryBars(habit: habit, metrics: metrics),
          ],
        ],
      ],
    );
  }
}

enum _DayState { completed, missed, future, notScheduled }

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.habit,
    required this.entries,
    required this.today,
  });

  final Habit habit;
  final List<HabitEntry> entries;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final schedule = LegacyHabitScheduleMapper.fromHabit(habit);
    final weekStart = today.addDays(1 - today.weekday);
    final completedDates = <String>{
      for (final entry in entries)
        if (entry.habitId == habit.id && entry.completed) entry.date,
    };
    final days = List<LocalDate>.generate(7, weekStart.addDays);
    final states = <LocalDate, _DayState>{
      for (final day in days)
        day: _stateFor(
          day: day,
          today: today,
          schedule: schedule,
          completedDates: completedDates,
        ),
    };
    final availableDays = days.where((day) => _isAvailable(day, schedule));
    final scheduled = schedule is TimesPerWeekSchedule
        ? schedule.target.clamp(0, availableDays.length)
        : availableDays.length;
    final completed = states.values
        .where((state) => state == _DayState.completed)
        .length;
    final visibleCompleted = completed.clamp(0, scheduled);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Semantics(
      container: true,
      label:
          '${context.l10n.thisWeek}: ${context.l10n.weeklyUnits(visibleCompleted, scheduled)}',
      child: HabiterSurface(
        padding: const EdgeInsets.all(HabiterSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.thisWeek,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: HabiterSpace.xs),
            Text(
              context.l10n.weeklyUnits(visibleCompleted, scheduled),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: HabiterSpace.md),
            LinearProgressIndicator(
              value: scheduled == 0 ? 0 : visibleCompleted / scheduled,
              minHeight: 7,
              borderRadius: BorderRadius.circular(HabiterRadius.pill),
            ),
            const SizedBox(height: HabiterSpace.lg),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final day in days)
                    Expanded(
                      child: _DayMarker(
                        label: DateFormat.E(
                          locale,
                        ).format(DateTime.utc(day.year, day.month, day.day)),
                        state: states[day]!,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: HabiterSpace.sm),
            for (final day in days)
              Semantics(
                label:
                    '${DateFormat.EEEE(locale).format(DateTime.utc(day.year, day.month, day.day))}: ${_stateLabel(context, states[day]!)}',
                child: const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  _DayState _stateFor({
    required LocalDate day,
    required LocalDate today,
    required HabitSchedule schedule,
    required Set<String> completedDates,
  }) {
    if (!_isAvailable(day, schedule)) return _DayState.notScheduled;
    if (completedDates.contains(day.toString())) return _DayState.completed;
    if (day.compareTo(today) > 0) return _DayState.future;
    if (schedule is TimesPerWeekSchedule) return _DayState.notScheduled;
    return _DayState.missed;
  }

  bool _isAvailable(LocalDate day, HabitSchedule schedule) {
    if (day.compareTo(LocalDate.fromDateTime(habit.createdAt)) < 0) {
      return false;
    }
    if (habit.isPausedOn(day.toString())) return false;
    final archivedAt = habit.archivedAt;
    if (archivedAt != null &&
        day.compareTo(LocalDate.fromDateTime(archivedAt)) >= 0) {
      final restoredAt = habit.restoredAt;
      if (restoredAt == null ||
          day.compareTo(LocalDate.fromDateTime(restoredAt)) < 0) {
        return false;
      }
    }
    return schedule is TimesPerWeekSchedule || schedule.isAvailableOn(day);
  }

  String _stateLabel(BuildContext context, _DayState state) => switch (state) {
    _DayState.completed => context.l10n.dayCompleted,
    _DayState.missed => context.l10n.dayMissed,
    _DayState.future => context.l10n.dayFuture,
    _DayState.notScheduled => context.l10n.dayNotScheduled,
  };
}

class _DayMarker extends StatelessWidget {
  const _DayMarker({required this.label, required this.state});

  final String label;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = state == _DayState.completed;
    final missed = state == _DayState.missed;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: HabiterSpace.sm),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: completed
                ? scheme.primary
                : missed
                ? scheme.errorContainer
                : scheme.surfaceContainerHighest,
            shape: completed ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: completed ? null : BorderRadius.circular(11),
            border: Border.all(
              color: state == _DayState.future
                  ? scheme.outline
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            completed
                ? Icons.check_rounded
                : missed
                ? Icons.remove_rounded
                : state == _DayState.future
                ? Icons.more_horiz_rounded
                : Icons.circle_outlined,
            size: 18,
            color: completed ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({
    required this.metrics,
    required this.prior,
    required this.recent,
  });

  final HabitMetrics metrics;
  final HabitMetrics prior;
  final HabitMetrics recent;

  @override
  Widget build(BuildContext context) {
    final percent = (metrics.completionRate * 100).round();
    final difference = recent.completionRate - prior.completionRate;
    final trend = difference > .05
        ? context.l10n.trendImproving
        : difference < -.05
        ? context.l10n.trendDeclining
        : context.l10n.trendSteady;
    final icon = difference > .05
        ? Icons.trending_up_rounded
        : difference < -.05
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;
    return HabiterSurface(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 68,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: metrics.completionRate,
                  strokeWidth: 7,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                Center(
                  child: Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: HabiterSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.lastThirtyDays,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: HabiterSpace.xs),
                Text(context.l10n.consistencyValue(percent)),
                const SizedBox(height: HabiterSpace.sm),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: HabiterSpace.xs),
                    Expanded(
                      child: Text(
                        trend,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsufficientHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: HabiterSpace.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.auto_graph_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: HabiterSpace.sm2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.notEnoughHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: HabiterSpace.xs),
              Text(
                context.l10n.notEnoughHistoryBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HistoryBars extends StatelessWidget {
  const _HistoryBars({required this.habit, required this.metrics});

  final Habit habit;
  final HabitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final weeks = metrics.weeks.length > 8
        ? metrics.weeks.sublist(metrics.weeks.length - 8)
        : metrics.weeks;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Semantics(
      label: weeks
          .map(
            (week) => '${week.weekStart}: ${week.completed}/${week.scheduled}',
          )
          .join(', '),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final week in weeks)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(week.rate * 100).round()}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: HabiterSpace.xs),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: week.rate.clamp(.08, 1),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: habit.color.asHabiterColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(HabiterRadius.compact),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: HabiterSpace.sm),
                        Text(
                          DateFormat.Md(locale).format(
                            DateTime.utc(
                              week.weekStart.year,
                              week.weekStart.month,
                              week.weekStart.day,
                            ),
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
