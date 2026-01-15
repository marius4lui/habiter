import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/habit.dart';

class BentoHabitCard extends StatelessWidget {
  const BentoHabitCard({
    super.key,
    required this.habit,
    this.completed = false,
    this.onEdit,
  });

  final Habit habit;
  final bool completed;
  final VoidCallback? onEdit;

  Color _parseColor(String colorStr) {
    try {
      final buffer = StringBuffer();
      if (colorStr.length == 6 || colorStr.length == 7) buffer.write('ff');
      buffer.write(colorStr.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final habitColor = _parseColor(habit.color);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl), // 32
        boxShadow: isDark ? AppShadows.neumorphSmDark : AppShadows.neumorph,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: habitColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  habit.icon, // Assuming emoji
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Content - wrap in Expanded to prevent overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  habit.name,
                  style: AppTextStyles.h3.copyWith(
                     color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  habit.category,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                
                // Simple Progress Bar
                ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    child: LinearProgressIndicator(
                      value: completed ? 1.0 : 0.0, 
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${habit.targetCount}x', // Mock target display
                        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                      ),
                      Text(
                        completed ? 'Done' : 'Pending',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
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
