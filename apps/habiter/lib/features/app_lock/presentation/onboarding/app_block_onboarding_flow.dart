import 'package:flutter/material.dart';

import '../../application/app_block_onboarding_controller.dart';
import '../../application/app_block_onboarding_state.dart';
import 'app_block_offer_page.dart';
import 'app_block_reconsider_page.dart';
import 'distraction_analysis_page.dart';
import 'usage_access_education_page.dart';

final class AppBlockOnboardingFlow extends StatefulWidget {
  const AppBlockOnboardingFlow({
    required this.controller,
    required this.onFinished,
    super.key,
  });

  final AppBlockOnboardingController controller;
  final ValueChanged<AppBlockOnboardingResult> onFinished;

  @override
  State<AppBlockOnboardingFlow> createState() => _AppBlockOnboardingFlowState();
}

final class _AppBlockOnboardingFlowState extends State<AppBlockOnboardingFlow>
    with WidgetsBindingObserver {
  AppBlockOnboardingResult? _reported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.reconcilePermissions();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      if (!widget.controller.initialized) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final state = widget.controller.state;
      final result = state.result;
      if (result != null && result != _reported) {
        _reported = result;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFinished(result);
        });
      }
      return AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        child: switch (state.stage) {
          AppBlockOnboardingStage.offer => AppBlockOfferPage(
            key: const ValueKey('offer'),
            controller: widget.controller,
          ),
          AppBlockOnboardingStage.reconsider => AppBlockReconsiderPage(
            key: const ValueKey('reconsider'),
            controller: widget.controller,
          ),
          AppBlockOnboardingStage.usageEducation => UsageAccessEducationPage(
            key: const ValueKey('usage-education'),
            controller: widget.controller,
          ),
          AppBlockOnboardingStage.discovery => const DistractionAnalysisPage(
            key: ValueKey('discovery'),
          ),
          _ => const Scaffold(
            key: ValueKey('app-block-next-stage'),
            body: Center(child: Text('Continue App Block setup')),
          ),
        },
      );
    },
  );
}
