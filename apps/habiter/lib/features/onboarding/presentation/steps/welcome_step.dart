import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../onboarding_scaffold.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    step: OnboardingStep.welcome,
    title: context.l10n.onboardingWelcomeTitle,
    subtitle: context.l10n.onboardingWelcomeBody,
    body: const _LeafMark(),
    primaryAction: FilledButton(
      onPressed: controller.start,
      child: Text(context.l10n.onboardingGetStarted),
    ),
  );
}

class _LeafMark extends StatelessWidget {
  const _LeafMark();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 144,
      height: 144,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(72),
          topRight: Radius.circular(72),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(72),
        ),
      ),
      child: Icon(
        Icons.eco_rounded,
        size: 76,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
