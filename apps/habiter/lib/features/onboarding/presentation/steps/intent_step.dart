import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../habits/presentation/templates/habit_template.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
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
    body: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: MediaQuery.textScalerOf(context).scale(1) > 1.3
            ? 148
            : 104,
        crossAxisSpacing: HabiterSpace.sm,
        mainAxisSpacing: HabiterSpace.sm,
      ),
      itemCount: OnboardingIntent.values.length,
      itemBuilder: (context, index) {
        final intent = OnboardingIntent.values[index];
        return Semantics(
          button: true,
          selected: controller.state.intent == intent,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                await context.read<HapticGateway>().selection();
                await controller.selectIntent(intent);
              },
              child: Padding(
                padding: const EdgeInsets.all(HabiterSpace.md),
                child: Row(
                  children: <Widget>[
                    Icon(_icon(intent), size: 30),
                    const SizedBox(width: HabiterSpace.sm),
                    Expanded(
                      child: Text(
                        _label(context, intent),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  IconData _icon(OnboardingIntent intent) => switch (intent) {
    OnboardingIntent.health => Icons.favorite_rounded,
    OnboardingIntent.fitness => Icons.fitness_center_rounded,
    OnboardingIntent.mindfulness => Icons.self_improvement_rounded,
    OnboardingIntent.learning => Icons.menu_book_rounded,
    OnboardingIntent.productivity => Icons.bolt_rounded,
    OnboardingIntent.home => Icons.home_rounded,
    OnboardingIntent.finance => Icons.savings_rounded,
    OnboardingIntent.other => Icons.auto_awesome_rounded,
  };
}
