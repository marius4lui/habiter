import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';

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
    final totalCompletions = provider.habitEntries.where((e) => e.completed).length;
    final double avgCompletionRate = activeHabits.isEmpty
        ? 0.0
        : activeHabits
                .map((h) => calculateHabitStats(h, provider.habitEntries).completionRate)
                .reduce((a, b) => a + b) /
            activeHabits.length;

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Analytics', style: AppTextStyles.h1),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _OverviewRow(
              activeHabits: activeHabits.length,
              totalCompletions: totalCompletions,
              avgCompletionRate: avgCompletionRate,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (activeHabits.isNotEmpty) ...[
              _WeeklyChartCard(
                habits: activeHabits,
                entries: provider.habitEntries,
                selectedHabit: selectedHabit,
                onSelectHabit: (id) => setState(() => selectedHabitId = id),
              ),
              const SizedBox(height: AppSpacing.lg),
              _HabitStatsGrid(
                habits: activeHabits,
                entries: provider.habitEntries,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _AIInsightsSection(
              insights: provider.aiInsights,
              onMarkRead: provider.markInsightAsRead,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.activeHabits,
    required this.totalCompletions,
    required this.avgCompletionRate,
  });

  final int activeHabits;
  final int totalCompletions;
  final double avgCompletionRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Active Habits',
            value: '$activeHabits',
            icon: Icons.incomplete_circle,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            title: 'Total Completions',
            value: '$totalCompletions',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            title: 'Avg. Success',
            value: '${avgCompletionRate.toStringAsFixed(0)}%',
            icon: Icons.trending_up,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({
    required this.habits,
    required this.entries,
    required this.selectedHabit,
    required this.onSelectHabit,
  });

  final List<Habit> habits;
  final List<HabitEntry> entries;
  final Habit? selectedHabit;
  final ValueChanged<String> onSelectHabit;

  @override
  Widget build(BuildContext context) {
    final habit = selectedHabit ?? (habits.isNotEmpty ? habits.first : null);
    final data = habit == null ? <WeeklyData>[] : getWeeklyData(habit.id, entries);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly progress', style: AppTextStyles.h3),
              DropdownButton<String>(
                value: habit?.id,
                underline: const SizedBox(),
                items: habits
                    .map((h) => DropdownMenuItem(
                          value: h.id,
                          child: Text(h.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSelectHabit(value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.isEmpty)
            const Text(
              'Track a habit to see weekly performance.',
              style: AppTextStyles.bodySecondary,
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data[index].week,
                              style: AppTextStyles.caption,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: _fromHex(habit!.color),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      spots: [
                        for (var i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i].completions.toDouble()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HabitStatsGrid extends StatelessWidget {
  const _HabitStatsGrid({required this.habits, required this.entries});

  final List<Habit> habits;
  final List<HabitEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: habits.map((habit) {
        final stats = calculateHabitStats(habit, entries);
        return SizedBox(
          width: MediaQuery.of(context).size.width > 900
              ? (MediaQuery.of(context).size.width - (AppSpacing.lg * 2) - (AppSpacing.md * 2)) / 3
              : MediaQuery.of(context).size.width > 640
                  ? (MediaQuery.of(context).size.width - (AppSpacing.lg * 2) - AppSpacing.md) / 2
                  : double.infinity,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(color: AppColors.borderLight),
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
                        style: AppTextStyles.h3,
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
                    _StatPill(label: 'Streak', value: '${stats.streakData.currentStreak}'),
                    _StatPill(
                        label: 'Success', value: '${stats.completionRate.toStringAsFixed(0)}%'),
                    _StatPill(label: 'Total', value: '${stats.totalCompletions}'),
                  ],
                ),
              ],
            ),
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
        color: _fromHex(colorHex).withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
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
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AIInsightsSection extends StatelessWidget {
  const _AIInsightsSection({required this.insights, required this.onMarkRead});

  final List<AIInsight> insights;
  final Future<void> Function(String id) onMarkRead;

  Color _typeColor(AIInsightType type) {
    switch (type) {
      case AIInsightType.recommendation:
        return AppColors.primary;
      case AIInsightType.motivation:
        return AppColors.success;
      case AIInsightType.analysis:
        return AppColors.warning;
      case AIInsightType.prediction:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('AI Insights', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (insights.isEmpty)
            const Text(
              'Insights will appear here after you track a few days and generate AI suggestions.',
              style: AppTextStyles.bodySecondary,
            )
          else
            Column(
              children: insights.take(6).map((insight) {
                final color = _typeColor(insight.type);
                return Card(
                  color: insight.isRead ? AppColors.backgroundDark : AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    side: BorderSide(
                      color: insight.isRead ? AppColors.border : color.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    onTap: () => onMarkRead(insight.id),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppBorderRadius.full),
                          ),
                          child: Text(
                            insight.type.name.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (insight.habitId != null)
                          Text(
                            'Habit',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(insight.title, style: AppTextStyles.h3),
                          const SizedBox(height: 4),
                          Text(insight.message, style: AppTextStyles.bodySecondary),
                          const SizedBox(height: 4),
                          Text(
                            'Confidence ${(insight.confidence * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: insight.isRead
                        ? const Icon(Icons.check, color: AppColors.textTertiary)
                        : const Icon(Icons.circle, size: 10, color: AppColors.primary),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

Color _fromHex(String hex) => Color(int.parse(hex.replaceFirst('#', '0xff')));
