import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/navigation/app_route.dart';
import '../core/design_system/adaptive_presentation.dart';
import '../core/design_system/components.dart';
import '../core/design_system/haptics.dart';
import '../core/design_system/layout.dart';
import '../core/design_system/tokens.dart';
import '../core/time/local_date.dart';
import '../features/home/application/habit_hub_model.dart';
import '../features/home/presentation/habit_navigation_wheel.dart';
import '../features/habits/presentation/habit_schedule_label.dart';
import '../features/history/presentation/habit_lifecycle_panel.dart';
import '../features/today/application/today_query.dart';
import '../l10n/l10n.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/habit_detail_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenDestination});

  final ValueChanged<HabitHubDestination>? onOpenDestination;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _wheelKey = GlobalKey(debugLabel: 'habit-navigation-wheel-state');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final latest = latestActiveHabit(provider.habits);
    final accent = latest?.color.asHabiterColor ?? const Color(0xff72b9aa);
    final overlay = dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _HubBackground(
          accent: accent,
          dark: dark,
          child: switch ((provider.loading, provider.error)) {
            (true, _) => const Center(child: CircularProgressIndicator()),
            (false, final String error) => _LoadError(
              message: error,
              onRetry: provider.refresh,
            ),
            _ => _content(provider, latest),
          },
        ),
      ),
    );
  }

  Widget _content(HabitProvider provider, Habit? latest) {
    final date = LocalDate.fromDateTime(provider.reminderNow);
    final snapshot = TodayQuery.forDate(
      date: date,
      habits: provider.habits,
      entries: provider.habitEntries,
    );
    final inactiveCount = provider.habits
        .where((habit) => !habit.isActive)
        .length;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final short = constraints.maxHeight < 680;
          final layout = HabiterLayout.fromSize(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          final topActions = _TopActions(
            leadingLabel: inactiveCount > 0
                ? context.l10n.pausedArchivedCount(inactiveCount)
                : context.l10n.appLock,
            leadingIcon: inactiveCount > 0
                ? Icons.history_rounded
                : Icons.lock_outline_rounded,
            leadingKey: Key(
              inactiveCount > 0
                  ? 'hub-inactive-habits-action'
                  : 'hub-app-lock-action',
            ),
            onOpenLeading: inactiveCount > 0
                ? () => _openLifecycle(provider)
                : () => _activate(HabitHubDestination.appLock),
            onOpenSettings: () => _activate(HabitHubDestination.settings),
          );
          final hero = latest == null
              ? _EmptyHabitHero(onCreate: () => _openEditor(context))
              : _LatestHabitHero(
                  habit: latest,
                  status: _statusFor(latest, snapshot),
                  onOpen: () => _openDetails(
                    provider,
                    latest,
                    snapshot.completed.any((habit) => habit.id == latest.id),
                    date.toString(),
                  ),
                  onComplete:
                      snapshot.pending.any((habit) => habit.id == latest.id)
                      ? () => _complete(provider, latest, date)
                      : null,
                );
          final wheel = HabitNavigationWheel(key: _wheelKey, onOpen: _activate);

          if (layout.atLeast(HabiterLayoutClass.expanded)) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(top: 0, left: 0, right: 0, child: topActions),
                Positioned.fill(
                  top: short ? 58 : 72,
                  bottom: HabiterSpace.lg,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.horizontalPagePadding,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: KeyedSubtree(
                                key: const Key('habit-hub-primary-pane'),
                                child: SingleChildScrollView(
                                  key: const Key('habit-hub-hero-scroll'),
                                  physics: const ClampingScrollPhysics(),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 500,
                                      ),
                                      child: hero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: HabiterSpace.xl),
                            Expanded(
                              flex: 6,
                              child: KeyedSubtree(
                                key: const Key('habit-hub-secondary-pane'),
                                child: Center(child: wheel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: 0, left: 0, right: 0, child: topActions),
              Positioned(
                top: short ? 58 : 72,
                left: 20,
                right: 20,
                bottom: short ? 226 : 244,
                child: KeyedSubtree(
                  key: const Key('habit-hub-primary-pane'),
                  child: SingleChildScrollView(
                    key: const Key('habit-hub-hero-scroll'),
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - (short ? 284 : 316))
                            .clamp(0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: hero,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: constraints.maxWidth <= 340 ? -24 : -12,
                child: KeyedSubtree(
                  key: const Key('habit-hub-secondary-pane'),
                  child: wheel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  _HabitTodayStatus _statusFor(Habit habit, TodaySnapshot snapshot) {
    if (snapshot.completed.any((item) => item.id == habit.id)) {
      return _HabitTodayStatus.completed;
    }
    if (snapshot.pending.any((item) => item.id == habit.id)) {
      return _HabitTodayStatus.open;
    }
    return _HabitTodayStatus.notPlanned;
  }

  void _activate(HabitHubDestination destination) {
    if (destination == HabitHubDestination.createHabit) {
      _openEditor(context);
      return;
    }
    if (widget.onOpenDestination case final callback?) {
      callback(destination);
      return;
    }
    final route = switch (destination) {
      HabitHubDestination.today => AppRoute.today,
      HabitHubDestination.analytics => AppRoute.analytics,
      HabitHubDestination.appLock => AppRoute.appLock,
      HabitHubDestination.rhythm => AppRoute.rhythm,
      HabitHubDestination.updates => AppRoute.updates,
      HabitHubDestination.settings => AppRoute.settings,
      HabitHubDestination.createHabit => AppRoute.today,
    };
    if (route == AppRoute.today) return;
    Navigator.of(context).pushNamed(AppRouteCodec.encode(route));
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
    showHabiterAdaptivePane<void>(
      context: context,
      frameSheet: false,
      builder: (_) => AddHabitSheet(habit: habit),
    );
  }

  void _openLifecycle(HabitProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: HabitLifecyclePanel(
          habits: provider.habits,
          onResume: provider.resumeHabit,
          onRestore: provider.restoreHabit,
          onDelete: provider.deleteHabit,
        ),
      ),
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

enum _HabitTodayStatus { open, completed, notPlanned }

class _HubBackground extends StatelessWidget {
  const _HubBackground({
    required this.accent,
    required this.dark,
    required this.child,
  });

  final Color accent;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = dark
        ? <Color>[
            Color.alphaBlend(
              accent.withValues(alpha: .08),
              const Color(0xff18312e),
            ),
            const Color(0xff393127),
            const Color(0xff3c292e),
          ]
        : <Color>[
            Color.alphaBlend(
              accent.withValues(alpha: .08),
              const Color(0xffc5e9df),
            ),
            const Color(0xffffd18d),
            const Color(0xffdfacaa),
          ];
    return DecoratedBox(
      key: const Key('habit-hub-background'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const <double>[0, .62, 1],
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions({
    required this.leadingLabel,
    required this.leadingIcon,
    required this.leadingKey,
    required this.onOpenLeading,
    required this.onOpenSettings,
  });

  final String leadingLabel;
  final IconData leadingIcon;
  final Key leadingKey;
  final VoidCallback onOpenLeading;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundAction(
          key: leadingKey,
          label: leadingLabel,
          icon: leadingIcon,
          onPressed: onOpenLeading,
        ),
        _RoundAction(
          key: const Key('hub-settings-action'),
          label: context.l10n.settings,
          icon: Icons.person_outline_rounded,
          onPressed: onOpenSettings,
        ),
      ],
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: dark
              ? Colors.white.withValues(alpha: .12)
              : Colors.white.withValues(alpha: .58),
          shape: CircleBorder(
            side: BorderSide(
              color: dark
                  ? Colors.white.withValues(alpha: .16)
                  : Colors.white.withValues(alpha: .68),
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 50,
              child: Icon(
                icon,
                size: 24,
                color: dark ? const Color(0xfff7f1e8) : const Color(0xff151515),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestHabitHero extends StatelessWidget {
  const _LatestHabitHero({
    required this.habit,
    required this.status,
    required this.onOpen,
    required this.onComplete,
  });

  final Habit habit;
  final _HabitTodayStatus status;
  final VoidCallback onOpen;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? const Color(0xfffbf4ea) : const Color(0xff111111);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final width = MediaQuery.sizeOf(context).width;
    final nameSize = textScale >= 1.75
        ? 27.0
        : width <= 340
        ? 38.0
        : 44.0;
    final statusLabel = switch (status) {
      _HabitTodayStatus.open => context.l10n.habitHubTodayOpen,
      _HabitTodayStatus.completed => context.l10n.completedToday,
      _HabitTodayStatus.notPlanned => context.l10n.habitHubNotPlanned,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.habitHubLatestHabit.toUpperCase(),
          style: TextStyle(
            color: foreground.withValues(alpha: .62),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.1,
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: context.l10n.openHabit(habit.name),
          onTap: onOpen,
          child: InkWell(
            key: const Key('latest-habit-open'),
            borderRadius: BorderRadius.circular(HabiterRadius.card),
            excludeFromSemantics: true,
            onTap: onOpen,
            child: Column(
              children: [
                Text(
                  habit.icon,
                  key: const Key('latest-habit-icon'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: textScale > 1.5 ? 38 : 48),
                ),
                const SizedBox(height: 10),
                Text(
                  habit.name,
                  key: const Key('latest-habit-name'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontSize: nameSize,
                    height: .98,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizedHabitSchedule(context.l10n, habit),
                  key: const Key('latest-habit-schedule'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground.withValues(alpha: .68),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: dark
                    ? Colors.black.withValues(alpha: .18)
                    : Colors.white.withValues(alpha: .48),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: .14)
                      : Colors.white.withValues(alpha: .62),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: switch (status) {
                            _HabitTodayStatus.open => const Color(0xff1c6b55),
                            _HabitTodayStatus.completed => const Color(
                              0xff39784f,
                            ),
                            _HabitTodayStatus.notPlanned =>
                              foreground.withValues(alpha: .46),
                          },
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        key: const Key('latest-habit-status'),
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onComplete case final complete?)
              Semantics(
                button: true,
                label: context.l10n.completeHabit(habit.name),
                child: Tooltip(
                  message: context.l10n.completeHabit(habit.name),
                  child: Material(
                    key: const Key('latest-habit-complete'),
                    color: foreground,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: complete,
                      child: SizedBox.square(
                        dimension: 50,
                        child: Icon(
                          Icons.check_rounded,
                          color: dark ? const Color(0xff192724) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyHabitHero extends StatelessWidget {
  const _EmptyHabitHero({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? const Color(0xfffbf4ea) : const Color(0xff111111);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      key: const Key('habit-hub-empty-state'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.eco_outlined,
          color: foreground,
          size: scale > 1.5 ? 40 : 48,
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.habitHubEmptyTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: scale > 1.5 ? 26 : 38,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.habitHubEmptyBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground.withValues(alpha: .72),
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          key: const Key('create-first-habit'),
          style: FilledButton.styleFrom(
            backgroundColor: foreground,
            foregroundColor: dark ? const Color(0xff192724) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: Text(context.l10n.createHabit),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync_problem_rounded, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    ),
  );
}
