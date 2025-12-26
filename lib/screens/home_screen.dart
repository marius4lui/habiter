import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';
import '../models/habit.dart';
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

    final allActiveHabits = provider.habits.where((h) => h.isActive).toList();
    final today = getTodayString();
    
    // Split into Pending and Completed
    final pendingHabits = <Habit>[];
    final completedHabits = <Habit>[];
    
    for (final habit in allActiveHabits) {
      if (isHabitCompletedToday(habit.id, provider.habitEntries)) {
        completedHabits.add(habit);
      } else {
        pendingHabits.add(habit);
      }
    }

    final completedToday = completedHabits.length;
    final totalActive = allActiveHabits.length;
    final completionRate = totalActive == 0 ? 0.0 : completedToday / totalActive;
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
                        activeHabits: totalActive,
                        completionRate: completionRate,
                        completedToday: completedToday,
                        onAddHabit: () => _openAddHabitSheet(context),
                      ),
                      const SizedBox(height: AppSpacing.md),

                    ],
                  ),
                ),
              ),
              if (allActiveHabits.isEmpty)
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
                            return HabitCard(habit: pendingHabits[index])
                                .animate(delay: (index * 50).ms) // Faster stagger
                                .slideY(
                                  begin: 0.2, // Subtle slide
                                  end: 0,
                                  duration: 400.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .fadeIn(duration: 400.ms);
                          },
                          childCount: pendingHabits.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppSpacing.sm, // Tighter spacing
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 2.5, // Much flatter/wider aspect ratio for compact cards
                        ),
                      );
                    },
                  ),
                ),
              if (completedHabits.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: _CompletedHabitsSection(habits: completedHabits),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg * 1.6),
        boxShadow: AppShadows.glow,
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _HeroStat(
                title: 'Completion',
                value: '${(completionRate * 100).round()}%',
                icon: Icons.bolt,
                accent: Colors.white,
              ),
              const SizedBox(width: AppSpacing.sm),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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


class _CompletedHabitsSection extends StatefulWidget {
  const _CompletedHabitsSection({required this.habits});

  final List<Habit> habits;

  @override
  State<_CompletedHabitsSection> createState() => _CompletedHabitsSectionState();
}

class _CompletedHabitsSectionState extends State<_CompletedHabitsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Completed (${widget.habits.length})',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
             children: widget.habits.map((h) => Opacity(
               opacity: 0.6,
               child: HabitCard(habit: h),
             )).toList(),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
