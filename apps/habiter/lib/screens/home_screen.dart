import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/haptics.dart';
import '../core/design_system/motion.dart';
import '../core/design_system/tokens.dart';
import '../core/time/local_date.dart';
import '../features/history/presentation/habit_lifecycle_panel.dart';
import '../features/habits/presentation/templates/habit_template.dart';
import '../features/onboarding/presentation/onboarding_empty_state.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/application/onboarding_state.dart';
import '../features/widgets/domain/widget_bridge.dart';
import '../features/widgets/presentation/widget_promotion_card.dart';
import '../features/today/application/today_query.dart';
import '../l10n/l10n.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/habit_detail_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCompleted = false;
  final ScrollController _scrollController = ScrollController();
  bool _fabExtended = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFab);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateFab)
      ..dispose();
    super.dispose();
  }

  void _updateFab() {
    final extended =
        !_scrollController.hasClients || _scrollController.offset < 28;
    if (extended != _fabExtended) setState(() => _fabExtended = extended);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) return _LoadError(onRetry: provider.refresh);

    final date = LocalDate.fromDateTime(DateTime.now());
    final snapshot = TodayQuery.forDate(
      date: date,
      habits: provider.habits,
      entries: provider.habitEntries,
    );
    final onboarding = context.watch<OnboardingController?>();
    final showWidgetPromotion =
        onboarding?.state.isComplete == true &&
        onboarding?.state.widgetPromotionState == WidgetPromotionState.pending;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: KeyedSubtree(
        key: const Key('add-habit-fab'),
        child: AnimatedSwitcher(
          duration: HabiterMotion.standard.duration(
            reduced: context.reduceMotion,
          ),
          child: _fabExtended
              ? FloatingActionButton.extended(
                  key: const ValueKey('extended-add-fab'),
                  heroTag: 'add-habit',
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.l10n.addHabit),
                )
              : FloatingActionButton.small(
                  key: const ValueKey('compact-add-fab'),
                  heroTag: 'add-habit',
                  tooltip: context.l10n.addHabit,
                  onPressed: () => _openEditor(context),
                  child: const Icon(Icons.add_rounded),
                ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HabiterContent(
                maxWidth: HabiterSize.wideContentMax,
                child: _TodayContent(
                  snapshot: snapshot,
                  allHabits: provider.habits,
                  showCompleted: _showCompleted,
                  onToggleCompleted: () =>
                      setState(() => _showCompleted = !_showCompleted),
                  onCreateHabit: () => _openEditor(context),
                  onComplete: (habit) => _complete(provider, habit, date),
                  onOpen: (habit, completed) =>
                      _openDetails(provider, habit, completed, date.toString()),
                  promotion: showWidgetPromotion
                      ? WidgetPromotionCard(
                          bridge: context.read<WidgetBridge>(),
                          onDismiss: onboarding!.dismissWidgetPromotion,
                          onPinned: onboarding.markWidgetPinned,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete(
    HabitProvider provider,
    Habit habit,
    LocalDate date,
  ) async {
    final result = await provider.completeHabit(habit.id, date.toString());
    if (!mounted || !result.changed) return;
    await context.read<HapticGateway>().success();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.todayDone),
        action: result.undoToken == null
            ? null
            : SnackBarAction(
                label: context.l10n.undoComplete,
                onPressed: () async {
                  final undo = await provider.undoCompletion(result.undoToken!);
                  if (undo.changed && mounted) {
                    await context.read<HapticGateway>().selection();
                  }
                },
              ),
      ),
    );
  }

  void _openEditor(BuildContext context, [Habit? habit]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHabitSheet(habit: habit),
    );
  }

  void _openDetails(
    HabitProvider provider,
    Habit habit,
    bool completed,
    String date,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => HabitDetailDialog(
        habit: habit,
        isCompleted: completed,
        onComplete: () async {
          if (completed) {
            await provider.toggleHabitCompletion(habit.id, date);
          } else {
            await _complete(provider, habit, LocalDate.parse(date));
          }
        },
        onArchive: () => provider.archiveHabit(habit.id),
        onPause: () => provider.pauseHabit(habit.id),
        onEdit: () => _openEditor(context, habit),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.snapshot,
    required this.allHabits,
    required this.showCompleted,
    required this.onToggleCompleted,
    required this.onCreateHabit,
    required this.onComplete,
    required this.onOpen,
    this.promotion,
  });

  final TodaySnapshot snapshot;
  final List<Habit> allHabits;
  final bool showCompleted;
  final VoidCallback onToggleCompleted;
  final VoidCallback onCreateHabit;
  final ValueChanged<Habit> onComplete;
  final void Function(Habit habit, bool completed) onOpen;
  final Widget? promotion;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = DateFormat.yMMMMEEEEd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(now);
    final greeting = now.hour < 12
        ? context.l10n.goodMorning
        : now.hour < 17
        ? context.l10n.goodAfternoon
        : context.l10n.goodEvening;

    if (allHabits.isEmpty) {
      return Column(
        children: [
          HabiterPageIntro(
            eyebrow: date,
            title: greeting,
            subtitle: context.l10n.todaySubtitle,
          ),
          const SizedBox(height: HabiterSpace.xl),
          OnboardingEmptyState(onCreateHabit: onCreateHabit),
        ],
      );
    }

    final next = snapshot.pending.firstOrNull;
    final primary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: HabiterMotion.standard.duration(
            reduced: context.reduceMotion,
          ),
          child: next == null
              ? snapshot.scheduled.isEmpty
                    ? const _NothingScheduledState(
                        key: ValueKey('nothing-scheduled-state'),
                      )
                    : const _CompletionState(key: ValueKey('complete-state'))
              : _NextHabitHero(
                  key: ValueKey('next-${next.id}'),
                  habit: next,
                  onComplete: () => onComplete(next),
                  onOpen: () => onOpen(next, false),
                ),
        ),
        if (snapshot.pending.length > 1) ...[
          const SizedBox(height: HabiterSpace.xl),
          HabiterSectionHeader(
            title: context.l10n.remainingToday,
            subtitle: context.l10n.remainingCount(snapshot.pending.length - 1),
          ),
          const SizedBox(height: HabiterSpace.sm2),
          for (final habit in snapshot.pending.skip(1)) ...[
            _HabitRow(
              habit: habit,
              onComplete: () => onComplete(habit),
              onOpen: () => onOpen(habit, false),
            ),
            const SizedBox(height: HabiterSpace.sm),
          ],
        ],
      ],
    );
    final secondary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot.completed.isNotEmpty)
          _CompletedPanel(
            habits: snapshot.completed,
            expanded: showCompleted,
            onToggle: onToggleCompleted,
            onOpen: (habit) => onOpen(habit, true),
          ),
        if (snapshot.completed.isNotEmpty)
          const SizedBox(height: HabiterSpace.sm2),
        HabitLifecyclePanel(
          habits: allHabits,
          onResume: context.read<HabitProvider>().resumeHabit,
          onRestore: context.read<HabitProvider>().restoreHabit,
          onDelete: context.read<HabitProvider>().deleteHabit,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HabiterPageIntro(
          eyebrow: date,
          title: greeting,
          subtitle: context.l10n.todaySubtitle,
        ),
        const SizedBox(height: HabiterSpace.lg),
        if (promotion != null) ...[
          promotion!,
          const SizedBox(height: HabiterSpace.lg),
        ],
        if (snapshot.scheduled.isNotEmpty) ...[
          _ProgressSummary(snapshot: snapshot),
          const SizedBox(height: HabiterSpace.lg),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < HabiterSize.expandedBreakpoint) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  primary,
                  const SizedBox(height: HabiterSpace.lg),
                  secondary,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: primary),
                const SizedBox(width: HabiterSpace.lg),
                Expanded(flex: 2, child: secondary),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.snapshot});
  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final complete = snapshot.completed.length;
    final total = snapshot.scheduled.length;
    return Semantics(
      container: true,
      label: context.l10n.habitsCompleted(complete, total),
      value: '${(snapshot.progress * 100).round()}%',
      child: HabiterSurface(
        padding: const EdgeInsets.all(HabiterSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.dailyProgress,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$complete / $total',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: HabiterSpace.sm2),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: snapshot.progress),
              duration: HabiterMotion.emphasized.duration(
                reduced: context.reduceMotion,
              ),
              curve: HabiterMotion.emphasized.curve,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                borderRadius: BorderRadius.circular(HabiterRadius.pill),
                backgroundColor: scheme.primary.withValues(alpha: .12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextHabitHero extends StatelessWidget {
  const _NextHabitHero({
    super.key,
    required this.habit,
    required this.onComplete,
    required this.onOpen,
  });

  final Habit habit;
  final VoidCallback onComplete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = habit.color.asHabiterColor;
    return Semantics(
      container: true,
      label: context.l10n.nextUp,
      child: Material(
        color: Color.alphaBlend(
          accent.withValues(
            alpha: theme.brightness == Brightness.dark ? .14 : .09,
          ),
          theme.colorScheme.surfaceContainerLow,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.prominent),
          side: BorderSide(color: accent.withValues(alpha: .28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(HabiterSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.nextUp.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: HabiterSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HabitIcon(habit: habit, size: 56),
                    const SizedBox(width: HabiterSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: HabiterSpace.xs),
                          Text(
                            _habitMeta(context, habit),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HabiterSpace.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(context.l10n.markAsComplete),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.onComplete,
    required this.onOpen,
  });
  final Habit habit;
  final VoidCallback onComplete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => HabiterSurface(
    onTap: onOpen,
    child: Row(
      children: [
        _HabitIcon(habit: habit),
        const SizedBox(width: HabiterSpace.sm2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                _habitMeta(context, habit),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: context.l10n.completeHabit(habit.name),
          onPressed: onComplete,
          icon: const Icon(Icons.check_rounded),
        ),
      ],
    ),
  );
}

class _HabitIcon extends StatelessWidget {
  const _HabitIcon({required this.habit, this.size = 48});
  final Habit habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = habit.color.asHabiterColor;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Text(habit.icon, style: TextStyle(fontSize: size * .45)),
    );
  }
}

class _CompletedPanel extends StatelessWidget {
  const _CompletedPanel({
    required this.habits,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
  });
  final List<Habit> habits;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Habit> onOpen;

  @override
  Widget build(BuildContext context) => HabiterSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        ListTile(
          onTap: onToggle,
          leading: Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(context.l10n.completedToday),
          subtitle: Text(context.l10n.todayCompleted(habits.length)),
          trailing: AnimatedRotation(
            turns: expanded ? .5 : 0,
            duration: HabiterMotion.quick.duration(
              reduced: context.reduceMotion,
            ),
            child: const Icon(Icons.expand_more_rounded),
          ),
        ),
        AnimatedSize(
          duration: HabiterMotion.standard.duration(
            reduced: context.reduceMotion,
          ),
          child: expanded
              ? Column(
                  children: [
                    const Divider(height: 1),
                    for (final habit in habits)
                      ListTile(
                        onTap: () => onOpen(habit),
                        leading: Text(
                          habit.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(habit.name),
                        trailing: const Icon(Icons.check_rounded),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    ),
  );
}

class _CompletionState extends StatelessWidget {
  const _CompletionState({super.key});

  @override
  Widget build(BuildContext context) => HabiterSurface(
    padding: const EdgeInsets.all(HabiterSpace.lg),
    child: Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 34,
        ),
        const SizedBox(width: HabiterSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.allHabitsCompleted,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: HabiterSpace.xs),
              Text(
                context.l10n.completedQuietly,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NothingScheduledState extends StatelessWidget {
  const _NothingScheduledState({super.key});

  @override
  Widget build(BuildContext context) => HabiterSurface(
    padding: const EdgeInsets.all(HabiterSpace.lg),
    child: Row(
      children: [
        Icon(
          Icons.wb_sunny_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 34,
        ),
        const SizedBox(width: HabiterSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.nothingScheduledTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: HabiterSpace.xs),
              Text(
                context.l10n.nothingScheduledBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: HabiterEmptyState(
      icon: Icons.sync_problem_outlined,
      title: context.l10n.bootstrapErrorTitle,
      body: context.l10n.permissionRequiredDesc,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(context.l10n.retry),
      ),
    ),
  );
}

String _habitMeta(BuildContext context, Habit habit) {
  final schedule = switch (habit.frequency) {
    HabitFrequency.daily => context.l10n.daily,
    HabitFrequency.weekly => context.l10n.perWeek(habit.targetCount),
    HabitFrequency.custom => context.l10n.onDays,
  };
  return '${localizedHabitCategory(context.l10n, habit.category)} · $schedule';
}
