import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';

final class OnboardingFactChip extends StatelessWidget {
  const OnboardingFactChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = emphasized
        ? colors.onPrimaryContainer
        : colors.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(HabiterRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HabiterSpace.sm2,
          vertical: HabiterSpace.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
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
