import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/habit.dart';
import '../theme/app_theme.dart';

/// A dialog that shows detailed information about a habit
/// with options to complete or archive it.
class HabitDetailDialog extends StatelessWidget {
  const HabitDetailDialog({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.onComplete,
    required this.onArchive,
    required this.onEdit,
  });

  final Habit habit;
  final bool isCompleted;
  final VoidCallback onComplete;
  final VoidCallback onArchive;
  final VoidCallback onEdit;

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xff')));
      }
      return Color(int.parse(colorStr));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = _parseColor(habit.color);
    final isClasslyHabit = habit.description == 'Imported from Classly';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColorsDark.surface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(
            color: isDark ? AppColorsDark.borderLight : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and name
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: habitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    border: Border.all(
                      color: habitColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      habit.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: AppTextStyles.h2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: habitColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppBorderRadius.full),
                            ),
                            child: Text(
                              habit.category,
                              style: AppTextStyles.caption.copyWith(
                                color: habitColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isClasslyHabit) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppBorderRadius.full),
                              ),
                              child: Text(
                                'Classly',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Details section
            if (habit.description != null && habit.description!.isNotEmpty) ...[
              _DetailRow(
                icon: Icons.description_outlined,
                label: 'Beschreibung',
                value: habit.description!,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            _DetailRow(
              icon: Icons.repeat,
              label: 'Frequenz',
              value: _frequencyText(habit.frequency),
            ),
            const SizedBox(height: AppSpacing.sm),

            _DetailRow(
              icon: Icons.flag_outlined,
              label: 'Ziel',
              value: '${habit.targetCount}x pro Tag',
            ),
            const SizedBox(height: AppSpacing.sm),

            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Erstellt am',
              value: DateFormat('dd.MM.yyyy').format(habit.createdAt),
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Status
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.pending,
                    color: isCompleted ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isCompleted ? 'Heute erledigt ✓' : 'Noch nicht erledigt',
                    style: AppTextStyles.body.copyWith(
                      color: isCompleted ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Action buttons - redesigned for better UX
            // Main action button (full width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  onComplete();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? AppColors.textSecondary
                      : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
                icon: Icon(
                  isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
                  size: 22,
                ),
                label: Text(
                  isCompleted ? 'Rückgängig machen' : 'Als erledigt markieren',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Secondary buttons row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Bearbeiten'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      onArchive();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('Archivieren'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _frequencyText(HabitFrequency freq) {
    switch (freq) {
      case HabitFrequency.daily:
        return 'Täglich';
      case HabitFrequency.weekly:
        return 'Wöchentlich';
      case HabitFrequency.custom:
        return 'Benutzerdefiniert';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }
}
