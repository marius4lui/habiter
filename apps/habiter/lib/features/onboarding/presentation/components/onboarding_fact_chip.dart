import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';

final class OnboardingFactChip extends StatelessWidget {
  const OnboardingFactChip({
    required this.code,
    required this.label,
    this.emphasized = false,
    super.key,
  });

  final String code;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = emphasized ? colors.onPrimary : colors.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(HabiterRadius.pill),
        border: Border.all(color: colors.primary.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HabiterSpace.sm2,
          vertical: HabiterSpace.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground.withValues(alpha: 0.68),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: HabiterSpace.sm),
            Flexible(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
