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
    final accent = _fromHex(habit.color);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppGradients.cardSheen,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.soft,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          onTap: () async {
            await provider.toggleHabitCompletion(habit.id, today);
          },
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: isCompleted ? 0.95 : 0.7),
                        accent.withValues(alpha: 0.35),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppBorderRadius.lg),
                      bottomLeft: Radius.circular(AppBorderRadius.lg),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -18,
                right: -10,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
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
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _AccentPill(
                          icon: Icons.local_fire_department,
                          label: '${streak.currentStreak} Tage',
                          color: accent,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _AccentPill(
                          icon: Icons.calendar_today_rounded,
                          label: '${habit.targetCount}x ${habit.frequency.name}',
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(AppBorderRadius.full),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            habit.category.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: isCompleted ? 1 : 0.75,
                          child: Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                size: 18,
                                color: isCompleted ? accent : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isCompleted ? 'Heute erledigt' : 'Noch offen',
                                style: AppTextStyles.caption.copyWith(
                                  color: isCompleted ? accent : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
        color: _fromHex(colorHex).withValues(alpha: 0.12),
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
          boxShadow: completed ? AppShadows.soft : null,
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

class _AccentPill extends StatelessWidget {
  const _AccentPill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
