import 'package:flutter/material.dart';

import '../../application/app_block_onboarding_controller.dart';
import 'app_block_onboarding_page.dart';

final class AppBlockOfferPage extends StatelessWidget {
  const AppBlockOfferPage({required this.controller, super.key});

  final AppBlockOnboardingController controller;

  @override
  Widget build(BuildContext context) => AppBlockOnboardingPage(
    title: 'Less distraction. More room for your habit.',
    subtitle:
        'Habiter can pause apps you choose until you complete what matters to you.',
    body: const _ProtectionIllustration(),
    primary: FilledButton(
      key: const Key('app-block-accept-offer'),
      onPressed: controller.acceptOffer,
      child: const Text('Protect my focus'),
    ),
    secondary: TextButton(
      key: const Key('app-block-decline-offer'),
      onPressed: controller.reconsider,
      child: const Text('Not now'),
    ),
  );
}

final class _ProtectionIllustration extends StatelessWidget {
  const _ProtectionIllustration();

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reducedMotion ? 1 : 0, end: 1),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Semantics(
        label: 'Distracting apps are paused before they reach your habit.',
        child: SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned(
                left: 20 + (70 * progress),
                top: 20,
                child: Opacity(
                  opacity: 1 - (0.35 * progress),
                  child: const _Tile('Social'),
                ),
              ),
              Positioned(
                left: 4 + (86 * progress),
                top: 92,
                child: Opacity(
                  opacity: 1 - (0.35 * progress),
                  child: const _Tile('Video'),
                ),
              ),
              Positioned(
                left: 28 + (62 * progress),
                top: 164,
                child: Opacity(
                  opacity: 1 - (0.35 * progress),
                  child: const _Tile('Feed'),
                ),
              ),
              Positioned(
                right: 10,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Icon(Icons.menu_book_rounded),
                        SizedBox(height: 8),
                        Text('Read for 10 min'),
                      ],
                    ),
                  ),
                ),
              ),
              Opacity(
                key: const Key('app-block-protection-line'),
                opacity: progress,
                child: const Icon(Icons.shield_outlined, size: 52),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Tile extends StatelessWidget {
  const _Tile(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}
