import 'package:flutter/material.dart';

import '../../application/app_block_onboarding_controller.dart';
import 'app_block_onboarding_page.dart';

final class AppBlockReconsiderPage extends StatelessWidget {
  const AppBlockReconsiderPage({required this.controller, super.key});

  final AppBlockOnboardingController controller;

  @override
  Widget build(BuildContext context) => AppBlockOnboardingPage(
    title: 'A small pause can interrupt autopilot.',
    subtitle: 'You stay in control. This is the only second invitation.',
    body: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _Path(
            title: 'Without App Block',
            steps: <String>['Impulse', 'Open app', 'Scroll', 'Time passes'],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _Path(
            title: 'With App Block',
            steps: <String>['Impulse', 'Open app', 'Habiter', 'Complete habit'],
          ),
        ),
      ],
    ),
    primary: FilledButton(
      key: const Key('app-block-accept-reconsider'),
      onPressed: controller.acceptOffer,
      child: const Text('Set up App Block'),
    ),
    secondary: TextButton(
      key: const Key('app-block-final-decline'),
      onPressed: controller.skip,
      child: const Text('Continue without App Block'),
    ),
  );
}

final class _Path extends StatelessWidget {
  const _Path({required this.title, required this.steps});
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          for (final step in steps) ...<Widget>[
            const SizedBox(height: 8),
            const Icon(Icons.arrow_downward_rounded, size: 16),
            Text(step, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}
