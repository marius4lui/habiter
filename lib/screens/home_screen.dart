import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/l10n.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/bento_habit_card.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/habit_detail_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    if (provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.error!,
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: provider.refresh,
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final allActiveHabits = provider.habits.where((h) => h.isActive).toList();
    
    // Calculate stats for daily progress
    final totalActive = allActiveHabits.length;
    final completedCount = allActiveHabits.where((h) => isHabitCompletedToday(h.id, provider.habitEntries)).length;
    final progress = totalActive == 0 ? 0.0 : completedCount / totalActive;

    return Scaffold(
      extendBody: true, // Important for glass effect if needed
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false, // Let content go behind bottom nav if needed, but we used column mostly
        child: Stack(
          children: [
            // Main Scrollable Content
            Positioned.fill(
              bottom: 100, // Leave space for bottom nav
              child: RefreshIndicator(
                onRefresh: provider.refresh,
                child: CustomScrollView(
                  slivers: [
                    // Header
                   const SliverToBoxAdapter(
                      child: DashboardHeader(),
                    ),
                    
                    // Calendar Strip
                    const SliverToBoxAdapter(
                      child: CalendarStrip(),
                    ),

                    // Daily Progress Hero
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: DailyProgressCard(
                          progress: progress,
                          completedCount: completedCount,
                          totalCount: totalActive,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg),
                    ),

                    // Incomplete Habits Grid
                    if (allActiveHabits.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            context.l10n.noHabitsYet,
                             style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
                          ),
                        ),
                      )
                    else ...[
                      // Filter for incomplete habits today
                      Builder(builder: (context) {
                        final incompleteHabits = allActiveHabits.where(
                          (h) => !isHabitCompletedToday(h.id, provider.habitEntries)
                        ).toList();
                        
                        if (incompleteHabits.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: Text(
                                context.l10n.allHabitsCompleted,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.85,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final habit = incompleteHabits[index];
                                final today = DateTime.now();
                                final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                                
                                return GestureDetector(
                                  onTap: () => _showHabitDetail(
                                    context,
                                    habit,
                                    false,
                                    dateStr,
                                    provider,
                                  ),
                                  child: BentoHabitCard(
                                    habit: habit,
                                    completed: false,
                                    onEdit: () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      builder: (_) => AddHabitSheet(habit: habit),
                                    ),
                                  ),
                                )
                                .animate(delay: (index * 50).ms)
                                .fadeIn()
                                .slideY(begin: 0.1, end: 0);
                              },
                              childCount: incompleteHabits.length,
                            ),
                          ),
                        );
                      }),
                      
                      // Completed Habits Section
                      Builder(builder: (context) {
                        final completedHabits = allActiveHabits.where(
                          (h) => isHabitCompletedToday(h.id, provider.habitEntries)
                        ).toList();
                        
                        if (completedHabits.isEmpty) {
                          return const SliverToBoxAdapter(child: SizedBox.shrink());
                        }
                        
                        return SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.xl),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, 
                                      color: AppColors.success, size: 20),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      context.l10n.todayCompleted(completedHabits.length),
                                      style: AppTextStyles.h3.copyWith(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                height: 90,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  itemCount: completedHabits.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                                  itemBuilder: (context, index) {
                                    final habit = completedHabits[index];
                                    final today = DateTime.now();
                                    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                                    
                                    return GestureDetector(
                                      onTap: () => _showHabitDetail(
                                        context, habit, true, dateStr, provider,
                                      ),
                                      child: Container(
                                        width: 90,
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                          border: Border.all(
                                            color: AppColors.success.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Stack(
                                              alignment: Alignment.bottomRight,
                                              children: [
                                                Text(habit.icon, style: const TextStyle(fontSize: 26)),
                                                Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.success,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              habit.name,
                                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                      
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120), // Bottom padding
                    ),
                  ],
                ),
              ),
            ),

            // Floating Action Button
            Positioned(
              bottom: 110,
              right: AppSpacing.lg,
              child: FloatingActionButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddHabitSheet(),
                ),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColorsDark.primary
                    : AppColors.primary,
                elevation: 8,
                child: const Icon(Icons.add, size: 28, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHabitDetail(
    BuildContext context,
    habit,
    bool isCompleted,
    String dateStr,
    HabitProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => HabitDetailDialog(
        habit: habit,
        isCompleted: isCompleted,
        onComplete: () => provider.toggleHabitCompletion(habit.id, dateStr),
        onArchive: () => provider.archiveHabit(habit.id),
        onEdit: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => AddHabitSheet(habit: habit),
        ),
      ),
    );
  }
}
