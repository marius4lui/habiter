import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../components/habit_illustration.dart';
import '../onboarding_scaffold.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    step: OnboardingStep.welcome,
    title: context.l10n.onboardingWelcomeTitle,
    subtitle: context.l10n.onboardingWelcomeBody,
    body: HabitIllustration(
      kind: HabitIllustrationKind.sprout,
      step: OnboardingStep.welcome,
      semanticLabel: context.l10n.onboardingWelcomeTitle,
      height: 230,
    ),
    primaryAction: FilledButton(
      onPressed: controller.start,
      child: Text(context.l10n.onboardingGetStarted),
    ),
  );
}
