import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../widgets/presentation/widget_preview.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../onboarding_scaffold.dart';

class WidgetIntroStep extends StatelessWidget {
  const WidgetIntroStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    step: OnboardingStep.widgetIntro,
    title: context.l10n.onboardingWidgetIntroTitle,
    subtitle: context.l10n.onboardingWidgetIntroBody,
    onBack: controller.back,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const WidgetPreview(),
        const SizedBox(height: 16),
        Text(
          context.l10n.onboardingWidgetResponsive,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    ),
    secondaryAction: TextButton(
      onPressed: controller.deferWidget,
      child: Text(context.l10n.onboardingWidgetLater),
    ),
    primaryAction: FilledButton.icon(
      onPressed: controller.beginWidgetPin,
      icon: const Icon(Icons.add_to_home_screen_rounded),
      label: Text(context.l10n.onboardingWidgetAdd),
    ),
  );
}
