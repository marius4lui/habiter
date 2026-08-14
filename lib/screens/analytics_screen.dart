import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../features/analytics/domain/habit_metrics.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? selectedHabitId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final activeHabits = provider.habits.where((h) => h.isActive).toList();
    final totalCompletions = provider.habitEntries
        .where((e) => e.completed)
        .length;
    final double avgCompletionRate = activeHabits.isEmpty
        ? 0.0
        : activeHabits
                  .map((habit) => provider.getHabitMetrics(habit.id).completionRate)
                  .reduce((a, b) => a + b) /
              activeHabits.length *
              100;

    Habit? selectedHabit;
    if (selectedHabitId != null) {
      try {
        selectedHabit = activeHabits.firstWhere((h) => h.id == selectedHabitId);
      } catch (_) {
        selectedHabit = null;
      }
    }
    selectedHabit ??= activeHabits.isNotEmpty ? activeHabits.first : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppGradientsDark.appShell
              : AppGradients.appShell,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              _AnalyticsHero(
                activeHabits: activeHabits.length,
                totalCompletions: totalCompletions,
                avgCompletionRate: avgCompletionRate,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (activeHabits.isNotEmpty) ...[
                _WeeklyChartCard(
                  habits: activeHabits,
                  selectedHabit: selectedHabit,
                  metrics: selectedHabit == null
                      ? null
                      : provider.getHabitMetrics(selectedHabit.id),
                  onSelectHabit: (id) => setState(() => selectedHabitId = id),
                ),
                const SizedBox(height: AppSpacing.lg),
                _HabitStatsGrid(
                  habits: activeHabits,
                  metricsFor: provider.getHabitMetrics,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({
    required this.activeHabits,
    required this.totalCompletions,
    required this.avgCompletionRate,
  });

  final int activeHabits;
  final int totalCompletions;
  final double avgCompletionRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? AppShadows.neumorphDark
            : AppShadows.neumorph,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics',
                      style: AppTextStyles.h1.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColorsDark.text
                            : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your progress, celebrate wins, adjust early.',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColorsDark.textSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_graph,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live overview',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _HeroNumber(
                label: 'Active habits',
                value: '$activeHabits',
                icon: Icons.blur_circular,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              _HeroNumber(
                label: 'Total wins',
                value: '$totalCompletions',
                icon: Icons.check_circle,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.md),
              _HeroNumber(
                label: 'Avg success',
                value: '${avgCompletionRate.toStringAsFixed(0)}%',
                icon: Icons.trending_up,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroNumber extends StatelessWidget {
  const _HeroNumber({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textSecondary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({
    required this.habits,
    required this.selectedHabit,
    required this.metrics,
    required this.onSelectHabit,
  });

  final List<Habit> habits;
  final Habit? selectedHabit;
  final HabitMetrics? metrics;
  final ValueChanged<String> onSelectHabit;

  @override
  Widget build(BuildContext context) {
    final habit = selectedHabit ?? (habits.isNotEmpty ? habits.first : null);
    final data = metrics?.weeks ?? const <WeeklyHabitMetric>[];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isDark ? AppGradientsDark.cardSheen : AppGradients.cardSheen,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: isDark ? AppColorsDark.border : AppColors.borderLight,
        ),
        boxShadow: isDark ? AppShadows.neumorphSmDark : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly progress',
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppColorsDark.text : AppColors.textMain,
                ),
              ),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColorsDark.surfaceMuted
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    border: Border.all(
                      color: isDark ? AppColorsDark.border : AppColors.border,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: habit?.id,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        items: habits
                            .map(
                              (h) => DropdownMenuItem(
                                value: h.id,
                                child: Text(
                                  h.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onSelectHabit(value);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.isEmpty)
            Text(
              'Track a habit to see weekly performance.',
              style: AppTextStyles.bodySecondary.copyWith(
                color: isDark
                    ? AppColorsDark.textSecondary
                    : AppColors.textSecondary,
              ),
            )
          else
            Semantics(
              label: data
                  .map(
                    (week) =>
                        '${week.weekStart}: ${week.completed} of ${week.scheduled}',
                  )
                  .join(', '),
              child: SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColorsDark.textSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data[index].weekStart.toString().substring(5),
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColorsDark.textSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: isDark
                          ? AppColorsDark.border
                          : AppColors.borderLight,
                    ),
                  ),
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [_fromHex(habit!.color), AppColors.primary],
                      ),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _fromHex(habit.color).withValues(alpha: 0.18),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      spots: [
                        for (var i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i].completed.toDouble()),
                      ],
                    ),
                  ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HabitStatsGrid extends StatelessWidget {
  const _HabitStatsGrid({required this.habits, required this.metricsFor});

  final List<Habit> habits;
  final HabitMetrics Function(String habitId) metricsFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: habits.map((habit) {
        final stats = metricsFor(habit.id);
        return SizedBox(
          width: MediaQuery.of(context).size.width > 900
              ? (MediaQuery.of(context).size.width -
                        (AppSpacing.lg * 2) -
                        (AppSpacing.md * 2)) /
                    3
              : MediaQuery.of(context).size.width > 640
              ? (MediaQuery.of(context).size.width -
                        (AppSpacing.lg * 2) -
                        AppSpacing.md) /
                    2
              : double.infinity,
          child: Builder(
            builder: (ctx) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppGradientsDark.cardSheen
                      : AppGradients.cardSheen,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: isDark
                        ? AppColorsDark.border
                        : AppColors.borderLight,
                  ),
                  boxShadow: isDark
                      ? AppShadows.neumorphSmDark
                      : AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _HabitBadge(colorHex: habit.color, icon: habit.icon),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            habit.name,
                            style: AppTextStyles.h3.copyWith(
                              color: isDark
                                  ? AppColorsDark.text
                                  : AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatPill(
                          label: 'Streak',
                          value: '${stats.currentStreak}',
                        ),
                        _StatPill(
                          label: 'Success',
                          value:
                              '${(stats.completionRate * 100).toStringAsFixed(0)}%',
                        ),
                        _StatPill(
                          label: 'Total',
                          value: '${stats.completed}',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _HabitBadge extends StatelessWidget {
  const _HabitBadge({required this.colorHex, required this.icon});

  final String colorHex;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _fromHex(colorHex).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: _fromHex(colorHex).withValues(alpha: 0.25)),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 18)),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColorsDark.primary : AppColors.primary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isDark
                ? AppColorsDark.textSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

Color _fromHex(String hex) => Color(int.parse(hex.replaceFirst('#', '0xff')));
