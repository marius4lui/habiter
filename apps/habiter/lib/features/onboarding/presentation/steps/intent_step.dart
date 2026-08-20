import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../habits/presentation/templates/habit_template.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../components/habit_illustration.dart';
import '../onboarding_scaffold.dart';

class IntentStep extends StatelessWidget {
  const IntentStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    step: OnboardingStep.intent,
    title: context.l10n.onboardingIntentTitle,
    subtitle: context.l10n.onboardingIntentBody,
    onBack: controller.back,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HabitIllustration(
          kind: HabitIllustrationKind.footsteps,
          step: OnboardingStep.intent,
          semanticLabel: context.l10n.onboardingIntentTitle,
          height: 142,
        ),
        const SizedBox(height: HabiterSpace.md),
        Wrap(
          key: const ValueKey<String>('onboarding-intent-choices'),
          spacing: HabiterSpace.sm,
          runSpacing: HabiterSpace.sm,
          children: <Widget>[
            for (var index = 0; index < OnboardingIntent.values.length; index++)
              _IntentChoice(
                index: index,
                label: _label(context, OnboardingIntent.values[index]),
                selected:
                    controller.state.intent == OnboardingIntent.values[index],
                onTap: () async {
                  await context.read<HapticGateway>().selection();
                  await controller.selectIntent(OnboardingIntent.values[index]);
                },
              ),
          ],
        ),
      ],
    ),
  );

  String _label(BuildContext context, OnboardingIntent intent) =>
      switch (intent) {
        OnboardingIntent.health => localizedHabitCategory(
          context.l10n,
          HabitCategories.health,
        ),
        OnboardingIntent.fitness => localizedHabitCategory(
          context.l10n,
          HabitCategories.fitness,
        ),
        OnboardingIntent.mindfulness => localizedHabitCategory(
          context.l10n,
          HabitCategories.mindfulness,
        ),
        OnboardingIntent.learning => localizedHabitCategory(
          context.l10n,
          HabitCategories.learning,
        ),
        OnboardingIntent.productivity => localizedHabitCategory(
          context.l10n,
          HabitCategories.productivity,
        ),
        OnboardingIntent.home => localizedHabitCategory(
          context.l10n,
          HabitCategories.home,
        ),
        OnboardingIntent.finance => localizedHabitCategory(
          context.l10n,
          HabitCategories.finance,
        ),
        OnboardingIntent.other => context.l10n.onboardingIntentOther,
      };
}

class _IntentChoice extends StatelessWidget {
  const _IntentChoice({
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainer,
        shape: StadiumBorder(
          side: BorderSide(
            color: scheme.primary.withValues(alpha: selected ? 1 : 0.22),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HabiterSpace.md,
                vertical: HabiterSpace.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${index + 1}'.padLeft(2, '0'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? scheme.onPrimary.withValues(alpha: 0.72)
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: HabiterSpace.sm),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
