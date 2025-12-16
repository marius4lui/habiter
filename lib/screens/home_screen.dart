import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';
import '../widgets/add_habit_sheet.dart';

import 'package:flutter_animate/flutter_animate.dart';
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
    final greeting = _greeting();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddHabitSheet(context),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Neues Habit'),
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
                      _HeroHeader(
                        today: today,
                        greeting: greeting,
                        activeHabits: activeHabits.length,
                        completionRate: completionRate,
                        completedToday: completedToday,
                        onAddHabit: () => _openAddHabitSheet(context),
                      ),
                      const SizedBox(height: AppSpacing.md),

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
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl + 72,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final crossAxisCount = width > 900
                          ? 3
                          : width > 620
                              ? 2
                              : 1;
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return HabitCard(habit: activeHabits[index])
                                .animate(delay: (index * 100).ms)
                                .slideY(
                                  begin: 0.5,
                                  end: 0,
                                  duration: 500.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .fadeIn(duration: 500.ms);
                          },
                          childCount: activeHabits.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.1,
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.today,
    required this.greeting,
    required this.activeHabits,
    required this.completionRate,
    required this.completedToday,
    required this.onAddHabit,
  });

  final String today;
  final String greeting;
  final int activeHabits;
  final double completionRate;
  final int completedToday;
  final VoidCallback onAddHabit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg * 1.6),
        boxShadow: AppShadows.glow,
      ),
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
                          greeting,
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Text(
                          formatDisplayDate(today),
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: Colors.white.withOpacity(0.86),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GlassIconButton(
                    icon: Icons.add,
                    onTap: onAddHabit,
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
                    title: 'Active',
                    value: '$activeHabits',
                    icon: Icons.blur_circular,
                    accent: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
                child: LinearProgressIndicator(
                  value: completionRate,
                  minHeight: 14,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's momentum",
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),
                  Text(
                    '$completedToday/$activeHabits',
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppGradients.cardSheen,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg * 1.2),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.flag_rounded, size: 38, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Starte dein Momentum', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Lege dein erstes Habit an und schau zu, wie die Routine wachsen kann.',
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
                'Habit erstellen',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
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
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.26)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.8),
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
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}


