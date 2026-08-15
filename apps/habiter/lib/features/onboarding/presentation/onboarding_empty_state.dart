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
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(HabiterSpace.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.eco_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
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
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: HabiterSpace.lg),
                    FilledButton.icon(
                      onPressed: onCreateHabit,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.createHabit),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
