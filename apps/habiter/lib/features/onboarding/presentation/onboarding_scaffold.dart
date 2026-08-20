import 'package:flutter/material.dart';

import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/onboarding_state.dart';
import 'onboarding_editorial.dart';

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
    final baseTheme = Theme.of(context);
    final colors = OnboardingEditorial.colorsFor(context, step);
    final scheme = baseTheme.colorScheme.copyWith(
      primary: colors.ink,
      onPrimary: colors.canvas,
      secondary: colors.accent,
      onSecondary: colors.ink,
      surface: colors.canvas,
      onSurface: colors.ink,
      surfaceContainer: colors.surface,
      surfaceContainerLow: colors.surface,
      surfaceContainerHighest: colors.surface,
      onSurfaceVariant: colors.softInk,
      outline: colors.softInk,
      outlineVariant: colors.ink.withValues(alpha: 0.2),
    );
    final localTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: colors.canvas,
      colorScheme: scheme,
      textTheme: baseTheme.textTheme.apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(OnboardingEditorial.actionHeight),
          backgroundColor: colors.ink,
          foregroundColor: colors.canvas,
          disabledBackgroundColor: colors.ink.withValues(alpha: 0.28),
          disabledForegroundColor: colors.canvas.withValues(alpha: 0.72),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(OnboardingEditorial.actionHeight),
          foregroundColor: colors.ink,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(OnboardingEditorial.actionHeight),
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.ink.withValues(alpha: 0.42)),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: baseTheme.cardTheme.copyWith(
        color: colors.surface,
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
    );

    return Theme(
      data: localTheme,
      child: Scaffold(
        key: const ValueKey<String>('onboarding-editorial-canvas'),
        backgroundColor: colors.canvas,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final short = constraints.maxHeight < 700;
              final expanded = constraints.maxWidth >= 720 && !short;
              final horizontalPadding = compact
                  ? HabiterSpace.md
                  : expanded
                  ? HabiterSpace.xxl
                  : HabiterSpace.lg;
              final titleSize = compact
                  ? OnboardingEditorial.compactTitleSize
                  : expanded
                  ? OnboardingEditorial.expandedTitleSize
                  : short
                  ? 48.0
                  : OnboardingEditorial.regularTitleSize;

              return Column(
                children: <Widget>[
                  _EditorialProgress(
                    step: step,
                    onBack: onBack,
                    horizontalPadding: horizontalPadding,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact || short ? HabiterSpace.sm2 : HabiterSpace.lg,
                        horizontalPadding,
                        HabiterSpace.lg,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: OnboardingEditorial.contentMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  key: const ValueKey<String>(
                                    'onboarding-editorial-title',
                                  ),
                                  style: TextStyle(
                                    color: colors.ink,
                                    fontSize: titleSize,
                                    height: 0.94,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -2.3,
                                  ),
                                ),
                              ),
                              if (subtitle != null) ...<Widget>[
                                const SizedBox(height: HabiterSpace.md),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 480,
                                  ),
                                  child: Text(
                                    subtitle!,
                                    style: localTheme.textTheme.bodyLarge
                                        ?.copyWith(
                                          color: colors.softInk,
                                          height: 1.35,
                                        ),
                                  ),
                                ),
                              ],
                              SizedBox(
                                height: compact
                                    ? HabiterSpace.lg
                                    : HabiterSpace.xl,
                              ),
                              body,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (primaryAction != null || secondaryAction != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        HabiterSpace.sm,
                        horizontalPadding,
                        HabiterSpace.lg,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: OnboardingEditorial.contentMaxWidth,
                          ),
                          child: _EditorialActions(
                            primaryAction: primaryAction,
                            secondaryAction: secondaryAction,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditorialProgress extends StatelessWidget {
  const _EditorialProgress({
    required this.step,
    required this.onBack,
    required this.horizontalPadding,
  });

  final OnboardingStep step;
  final VoidCallback? onBack;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingEditorial.colorsFor(context, step);
    final stepIndex = OnboardingProgress.indexOf(step);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        HabiterSpace.sm,
        horizontalPadding,
        0,
      ),
      child: Row(
        children: <Widget>[
          SizedBox.square(
            dimension: HabiterState.minimumTarget,
            child: onBack == null
                ? null
                : IconButton(
                    key: const ValueKey<String>('onboarding-back'),
                    onPressed: onBack,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          const SizedBox(width: HabiterSpace.sm),
          Expanded(
            child: Semantics(
              label: context.l10n.onboardingStepProgress(
                stepIndex,
                OnboardingProgress.total,
              ),
              child: Row(
                key: const ValueKey<String>('onboarding-segmented-progress'),
                children: <Widget>[
                  for (var index = 0; index < OnboardingProgress.total; index++)
                    Expanded(
                      child: Container(
                        key: ValueKey<String>('onboarding-progress-$index'),
                        height: 3,
                        margin: EdgeInsetsDirectional.only(
                          end: index == OnboardingProgress.total - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: index < stepIndex
                              ? colors.ink
                              : colors.ink.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            HabiterRadius.pill,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: HabiterSpace.sm),
          const SizedBox.square(dimension: HabiterState.minimumTarget),
        ],
      ),
    );
  }
}

class _EditorialActions extends StatelessWidget {
  const _EditorialActions({this.primaryAction, this.secondaryAction});

  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final stacked =
        MediaQuery.sizeOf(context).width < 420 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (primaryAction != null) primaryAction!,
          if (primaryAction != null && secondaryAction != null)
            const SizedBox(height: HabiterSpace.sm),
          if (secondaryAction != null) secondaryAction!,
        ],
      );
    }
    return Row(
      children: <Widget>[
        if (primaryAction != null) Expanded(flex: 2, child: primaryAction!),
        if (primaryAction != null && secondaryAction != null)
          const SizedBox(width: HabiterSpace.sm2),
        if (secondaryAction != null) Expanded(child: secondaryAction!),
      ],
    );
  }
}
