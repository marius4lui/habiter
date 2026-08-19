import 'package:flutter/material.dart';

import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/onboarding_state.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.body,
    this.subtitle,
    this.primaryAction,
    this.secondaryAction,
    this.onBack,
  });

  final OnboardingStep step;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepIndex = OnboardingProgress.indexOf(step);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HabiterSpace.md,
                HabiterSpace.sm,
                HabiterSpace.md,
                0,
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: onBack == null
                        ? null
                        : IconButton(
                            onPressed: onBack,
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                  ),
                  Expanded(
                    child: Semantics(
                      label: context.l10n.onboardingStepProgress(
                        stepIndex,
                        OnboardingProgress.total,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(HabiterRadius.pill),
                        child: LinearProgressIndicator(
                          value: stepIndex / OnboardingProgress.total,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48, height: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(HabiterSpace.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: theme.textTheme.headlineLarge,
                          ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: HabiterSpace.sm),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: HabiterSpace.xl),
                        body,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (primaryAction != null || secondaryAction != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HabiterSpace.lg,
                    HabiterSpace.sm,
                    HabiterSpace.lg,
                    HabiterSpace.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked =
                            constraints.maxWidth < 360 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.3;
                        if (stacked) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              if (primaryAction != null) primaryAction!,
                              if (primaryAction != null &&
                                  secondaryAction != null)
                                const SizedBox(height: HabiterSpace.sm),
                              if (secondaryAction != null) secondaryAction!,
                            ],
                          );
                        }
                        return Row(
                          children: <Widget>[
                            if (secondaryAction != null)
                              Expanded(child: secondaryAction!),
                            if (secondaryAction != null &&
                                primaryAction != null)
                              const SizedBox(width: HabiterSpace.sm),
                            if (primaryAction != null)
                              Expanded(flex: 2, child: primaryAction!),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
