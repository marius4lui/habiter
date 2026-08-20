import 'package:flutter/material.dart';

import '../../application/app_block_onboarding_controller.dart';
import 'app_block_onboarding_page.dart';

final class OverlayEducationPage extends StatelessWidget {
  const OverlayEducationPage({required this.controller, super.key});

  final AppBlockOnboardingController controller;

  @override
  Widget build(BuildContext context) => AppBlockOnboardingPage(
    title: 'A clear pause when a protected app opens',
    subtitle:
        'Overlay access lets Habiter show the habits that currently protect that app.',
    body: const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(Icons.lock_outline_rounded, size: 48),
            SizedBox(height: 16),
            Text('This app is paused'),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.radio_button_unchecked_rounded),
              title: Text('Read for 10 min'),
            ),
            Text('Open Habiter to complete the requirement, or return home.'),
          ],
        ),
      ),
    ),
    primary: FilledButton.icon(
      key: const Key('app-block-request-overlay'),
      onPressed: controller.requestOverlay,
      icon: const Icon(Icons.layers_rounded),
      label: const Text('Allow overlay'),
    ),
    secondary: TextButton(
      onPressed: controller.defer,
      child: const Text('Maybe later'),
    ),
  );
}
