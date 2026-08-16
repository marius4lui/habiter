import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../../models/habit.dart';
import '../../application/onboarding_controller.dart';
import '../onboarding_scaffold.dart';

class HabitReadyStep extends StatelessWidget {
  const HabitReadyStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.state.habitDraft!;
    return OnboardingScaffold(
      step: 6,
      title: context.l10n.onboardingHabitReadyTitle,
      subtitle: context.l10n.onboardingHabitReadyBody,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(HabiterSpace.xl),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: <Widget>[
              Text(draft.icon, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: HabiterSpace.md),
              Text(
                draft.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: HabiterSpace.xs),
              Text(
                _schedule(context, draft.frequency, draft.targetCount),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HabiterSpace.md),
              const Icon(Icons.check_circle_rounded, size: 42),
            ],
          ),
        ),
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
