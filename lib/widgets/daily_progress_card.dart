import 'package:flutter/material.dart';

import '../core/design_system/motion.dart';
import '../core/design_system/tokens.dart';
import '../l10n/l10n.dart';

class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({
    super.key,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  final double progress;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final resolvedProgress = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: resolvedProgress),
      duration: HabiterMotion.emphasized.duration(
        reduced: context.reduceMotion,
      ),
      curve: HabiterMotion.emphasized.curve,
      builder: (context, animatedProgress, _) {
        return Semantics(
          container: true,
          label: l10n.habitsCompleted(completedCount, totalCount),
          value: '${(animatedProgress * 100).round()}%',
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(HabiterSpace.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 420 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  final details = _ProgressDetails(
                    progress: animatedProgress,
                    completedCount: completedCount,
                    totalCount: totalCount,
                  );
                  final indicator = _ProgressIndicator(
                    progress: animatedProgress,
                    color: theme.colorScheme.primary,
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        details,
                        const SizedBox(height: HabiterSpace.lg),
                        Align(alignment: Alignment.center, child: indicator),
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: details),
                      const SizedBox(width: HabiterSpace.lg),
                      indicator,
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressDetails extends StatelessWidget {
  const _ProgressDetails({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  final double progress;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(l10n.yourDailyFlow, style: theme.textTheme.headlineSmall),
        const SizedBox(height: HabiterSpace.xs),
        Text(l10n.keepMomentum, style: theme.textTheme.bodyMedium),
        const SizedBox(height: HabiterSpace.md),
        Wrap(
          spacing: HabiterSpace.sm,
          runSpacing: HabiterSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Chip(label: Text(progress >= 1 ? l10n.completed : l10n.onTrack)),
          ],
        ),
        const SizedBox(height: HabiterSpace.xs),
        Text(
          l10n.habitsCompleted(completedCount, totalCount),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 88,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
          Icon(
            progress >= 1 ? Icons.check_rounded : Icons.eco_outlined,
            color: color,
            size: 32,
          ),
        ],
      ),
    );
  }
}
