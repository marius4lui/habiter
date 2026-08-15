import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/tokens.dart';
import '../features/analytics/domain/habit_metrics.dart';
import '../features/coaching/presentation/recovery_card.dart';
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
                  eyebrow: context.l10n.analytics,
                  title: context.l10n.analyticsTitle,
                  subtitle: context.l10n.analyticsBody,
                ),
                const SizedBox(height: HabiterSpace.lg),
                _Overview(
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
                  _WeeklyChart(
                    habit: selected,
                    metrics: provider.getHabitMetrics(selected.id),
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
                  const SizedBox(height: HabiterSpace.xl),
                  HabiterSectionHeader(
                    title: context.l10n.activeHabitsLabel,
                    subtitle: context.l10n.analyticsSubtitle,
                  ),
                  const SizedBox(height: HabiterSpace.sm2),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 620;
                      final width = twoColumns
                          ? (constraints.maxWidth - HabiterSpace.sm2) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: HabiterSpace.sm2,
                        runSpacing: HabiterSpace.sm2,
                        children: [
                          for (final habit in habits)
                            SizedBox(
                              width: width,
                              child: _HabitMetricCard(
                                habit: habit,
                                metrics: provider.getHabitMetrics(habit.id),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.active,
    required this.completed,
    required this.average,
  });
  final int active;
  final int completed;
  final double average;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 430 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.35;
      final items = [
        _Metric(
          icon: Icons.eco_outlined,
          value: '$active',
          label: context.l10n.activeHabitsLabel,
        ),
        _Metric(
          icon: Icons.check_circle_outline,
          value: '$completed',
          label: context.l10n.totalWinsLabel,
        ),
        _Metric(
          icon: Icons.trending_up_rounded,
          value: '${(average * 100).round()}%',
          label: context.l10n.averageSuccessLabel,
        ),
      ];
      return HabiterSurface(
        padding: const EdgeInsets.all(HabiterSpace.sm),
        child: compact
            ? Column(children: items)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final item in items) Expanded(child: item)],
              ),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(HabiterSpace.sm),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: HabiterSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.titleLarge),
                Text(
                  label,
                  maxLines: 2,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.habit, required this.metrics});
  final Habit habit;
  final HabitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeks = metrics.weeks.length > 8
        ? metrics.weeks.sublist(metrics.weeks.length - 8)
        : metrics.weeks;
    return HabiterSurface(
      padding: const EdgeInsets.all(HabiterSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.weeklyProgress, style: theme.textTheme.titleLarge),
          const SizedBox(height: HabiterSpace.xs),
          Text(
            context.l10n.trackToSeeProgress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: HabiterSpace.lg),
          if (weeks.isEmpty)
            SizedBox(
              height: 160,
              child: Center(child: Text(context.l10n.insightsAppearHere)),
            )
          else
            Semantics(
              label: weeks
                  .map(
                    (week) =>
                        '${week.weekStart}: ${week.completed}/${week.scheduled}',
                  )
                  .join(', '),
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: weeks
                          .map((week) => week.scheduled.toDouble())
                          .fold<double>(
                            1,
                            (max, value) => value > max ? value : max,
                          ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.colorScheme.outlineVariant,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, _) => Text(
                              '${value.round()}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              final index = value.round();
                              if (index < 0 || index >= weeks.length) {
                                return const SizedBox();
                              }
                              final date = DateTime.parse(
                                '${weeks[index].weekStart}T00:00:00',
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat.Md(
                                    Localizations.localeOf(
                                      context,
                                    ).toLanguageTag(),
                                  ).format(date),
                                  style: theme.textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var index = 0; index < weeks.length; index++)
                              FlSpot(
                                index.toDouble(),
                                weeks[index].completed.toDouble(),
                              ),
                          ],
                          isCurved: true,
                          barWidth: 3,
                          color: habit.color.asHabiterColor,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: habit.color.asHabiterColor.withValues(
                              alpha: .1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HabitMetricCard extends StatelessWidget {
  const _HabitMetricCard({required this.habit, required this.metrics});
  final Habit habit;
  final HabitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = [
      (context.l10n.streakLabel, '${metrics.currentStreak}'),
      (context.l10n.bestStreakLabel, '${metrics.longestStreak}'),
      (context.l10n.successLabel, '${(metrics.completionRate * 100).round()}%'),
    ];
    return HabiterSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(habit.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: HabiterSpace.sm),
              Expanded(
                child: Text(habit.name, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: HabiterSpace.md),
          Wrap(
            spacing: HabiterSpace.md,
            runSpacing: HabiterSpace.sm,
            children: [
              for (final value in values)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 84),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.$2,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: habit.color.asHabiterColor,
                        ),
                      ),
                      Text(
                        value.$1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
