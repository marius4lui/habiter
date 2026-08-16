import 'package:flutter/material.dart';

import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';

class OnboardingEmptyState extends StatelessWidget {
  const OnboardingEmptyState({super.key, required this.onCreateHabit});

  final VoidCallback onCreateHabit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HabiterSpace.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Semantics(
            container: true,
            header: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      HabiterRadius.prominent,
                    ),
                  ),
                  child: Icon(
                    Icons.eco_outlined,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: HabiterSpace.lg),
                Text(
                  l10n.startMomentum,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: HabiterSpace.sm),
                Text(
                  l10n.startMomentumDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: HabiterSpace.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HabiterSpace.md,
                    vertical: HabiterSpace.sm2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(HabiterRadius.pill),
                  ),
                  child: Text(
                    l10n.emptyStarterExamples,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: HabiterSpace.lg),
                FilledButton.icon(
                  onPressed: onCreateHabit,
                  icon: const Icon(Icons.grid_view_rounded),
                  label: Text(l10n.chooseHabit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
