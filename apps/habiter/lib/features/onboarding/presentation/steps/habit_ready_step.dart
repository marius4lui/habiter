import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../../models/habit.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../components/habit_illustration.dart';
import '../onboarding_scaffold.dart';

class HabitReadyStep extends StatelessWidget {
  const HabitReadyStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.state.habitDraft!;
    return OnboardingScaffold(
      step: OnboardingStep.habitReady,
      title: context.l10n.onboardingHabitReadyTitle,
      subtitle: context.l10n.onboardingHabitReadyBody,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          HabitIllustration(
            kind: HabitIllustrationKind.growth,
            step: OnboardingStep.habitReady,
            semanticLabel: context.l10n.onboardingHabitReadyTitle,
            height: 168,
          ),
          const SizedBox(height: HabiterSpace.md),
          Container(
            constraints: const BoxConstraints(minHeight: 86),
            padding: const EdgeInsets.all(HabiterSpace.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(HabiterRadius.prominent),
            ),
            child: Row(
              children: <Widget>[
                Text(draft.icon, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: HabiterSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        draft.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _schedule(context, draft.frequency, draft.targetCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      primaryAction: FilledButton(
        onPressed: controller.showWidgetIntro,
        child: Text(context.l10n.continueLabel),
      ),
    );
  }

  String _schedule(
    BuildContext context,
    HabitFrequency frequency,
    int target,
  ) => switch (frequency) {
    HabitFrequency.daily => context.l10n.onboardingEveryDay,
    HabitFrequency.weekly => context.l10n.onboardingTimesPerWeek(target),
    HabitFrequency.custom => context.l10n.onboardingSpecificDays,
  };
}
