import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
  });

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final entries = provider.habitEntries;
    final today = getTodayString();
    final isCompleted = isHabitCompletedToday(habit.id, entries);
    final streak = calculateStreak(habit.id, entries);

    return Material(
      color: AppColors.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        onTap: () async {
          await provider.toggleHabitCompletion(habit.id, today);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HabitIcon(colorHex: habit.color, icon: habit.icon),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (habit.description != null && habit.description!.isNotEmpty)
                          Text(
                            habit.description!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _CompletionToggle(
                    colorHex: habit.color,
                    completed: isCompleted,
                    onToggle: () => provider.toggleHabitCompletion(habit.id, today),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (streak.currentStreak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _fromHex(habit.color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppBorderRadius.full),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${streak.currentStreak} day streak',
                            style: AppTextStyles.caption.copyWith(
                              color: _fromHex(habit.color),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    ),
                    child: Text(
                      habit.category.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
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
}

class _HabitIcon extends StatelessWidget {
  const _HabitIcon({required this.colorHex, required this.icon});

  final String colorHex;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _fromHex(colorHex).withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      alignment: Alignment.center,
      child: Text(
        icon,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class _CompletionToggle extends StatelessWidget {
  const _CompletionToggle({
    required this.colorHex,
    required this.completed,
    required this.onToggle,
  });

  final String colorHex;
  final bool completed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = _fromHex(colorHex);
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          border: Border.all(
            color: completed ? color : AppColors.border,
            width: 2,
          ),
          color: completed ? color : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: completed ? 1 : 0,
          child: const Icon(Icons.check, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

Color _fromHex(String hex) => Color(int.parse(hex.replaceFirst('#', '0xff')));
