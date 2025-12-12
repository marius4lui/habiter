import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/ai_setup_dialog.dart';
import '../widgets/habit_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openAddHabitSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddHabitSheet(),
    );
  }

  Future<void> _openAISetup(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const AISetupDialog(),
    );
  }

  Future<void> _generateInsights(BuildContext context) async {
    final provider = context.read<HabitProvider>();
    await provider.generateInsights();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI insights generated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.error!, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: provider.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final activeHabits = provider.habits.where((h) => h.isActive).toList();
    final today = getTodayString();
    final completedToday = activeHabits
        .where((habit) => isHabitCompletedToday(habit.id, provider.habitEntries))
        .length;
    final completionRate =
        activeHabits.isEmpty ? 0.0 : completedToday / activeHabits.length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddHabitSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(AppBorderRadius.lg * 1.3),
                          boxShadow: AppShadows.elevated,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Stack(
                          children: [
                            const Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(gradient: AppGradients.halo),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _greeting(),
                                            style: AppTextStyles.h1.copyWith(
                                              color: Colors.white,
                                              letterSpacing: -0.8,
                                            ),
                                          ),
                                          Text(
                                            formatDisplayDate(today),
                                            style: AppTextStyles.bodySecondary.copyWith(
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _GlassIconButton(
                                      icon: Icons.auto_awesome,
                                      onTap: () => _generateInsights(context),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    _GlassIconButton(
                                      icon: Icons.settings,
                                      onTap: () => _openAISetup(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    _HeroStat(
                                      title: 'Completion',
                                      value: '${(completionRate * 100).round()}%',
                                      icon: Icons.bolt,
                                      accent: Colors.white,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    _HeroStat(
                                      title: 'Active habits',
                                      value: '${activeHabits.length}',
                                      icon: Icons.check_circle_outline,
                                      accent: Colors.white,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                                  child: LinearProgressIndicator(
                                    value: completionRate,
                                    minHeight: 12,
                                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Today's momentum",
                                      style: AppTextStyles.bodySecondary.copyWith(
                                        color: Colors.white.withValues(alpha: 0.82),
                                      ),
                                    ),
                                    Text(
                                      '$completedToday/${activeHabits.length}',
                                      style: AppTextStyles.h3.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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
              if (activeHabits.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(onAdd: () => _openAddHabitSheet(context)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl + 72, // allow for FAB
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final crossAxisCount = width > 900
                          ? 3
                          : width > 600
                              ? 2
                              : 1;
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => HabitCard(habit: activeHabits[index]),
                          childCount: activeHabits.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.15,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(AppBorderRadius.full),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.flag, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Start your journey', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Create your first habit to begin tracking and building momentum.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
            ),
            label: const Text(
              'Create a habit',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.full),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
