import 'package:flutter/material.dart';

import '../../application/app_block_onboarding_controller.dart';
import 'app_block_onboarding_page.dart';

final class DistractionAnalysisPage extends StatelessWidget {
  const DistractionAnalysisPage({required this.controller, super.key});

  final AppBlockOnboardingController controller;

  @override
  Widget build(BuildContext context) => AppBlockOnboardingPage(
    title: controller.loading
        ? 'Looking only at this device…'
        : 'App analysis could not finish',
    subtitle: controller.loading ? null : controller.diagnostic,
    body: controller.loading
        ? const Center(child: CircularProgressIndicator())
        : const SizedBox.shrink(),
    primary: controller.loading
        ? const SizedBox.shrink()
        : FilledButton(
            key: const Key('app-block-retry-discovery'),
            onPressed: controller.discover,
            child: const Text('Retry'),
          ),
    secondary: TextButton(
      key: const Key('app-block-defer-discovery'),
      onPressed: controller.defer,
      child: const Text('Maybe later'),
    ),
  );
}
