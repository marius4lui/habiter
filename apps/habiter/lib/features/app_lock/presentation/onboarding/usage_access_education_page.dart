import 'package:flutter/material.dart';

import '../../application/app_block_onboarding_controller.dart';
import 'app_block_onboarding_page.dart';

final class UsageAccessEducationPage extends StatelessWidget {
  const UsageAccessEducationPage({required this.controller, super.key});

  final AppBlockOnboardingController controller;

  @override
  Widget build(BuildContext context) => AppBlockOnboardingPage(
    title: 'How Habiter finds possible distractions',
    subtitle:
        'Usage Access lets Habiter compare recent foreground time and last use on this device.',
    body: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Fact(Icons.check_rounded, 'Processed locally: app time and last use'),
        _Fact(
          Icons.close_rounded,
          'Not read: messages or content in other apps',
        ),
        _Fact(Icons.close_rounded, 'Not read: passwords'),
        SizedBox(height: 24),
        Text('Your recommendations stay on this device.'),
      ],
    ),
    primary: FilledButton.icon(
      key: const Key('app-block-request-usage'),
      onPressed: controller.requestUsageAccess,
      icon: const Icon(Icons.query_stats_rounded),
      label: const Text('Analyze apps'),
    ),
    secondary: TextButton(
      onPressed: controller.defer,
      child: const Text('Maybe later'),
    ),
  );
}

final class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(text),
  );
}
