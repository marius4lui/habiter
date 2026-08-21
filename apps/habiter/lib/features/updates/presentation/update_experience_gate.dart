import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../application/update_controller.dart';
import '../domain/update_models.dart';
import 'release_story_screen.dart';
import 'update_install_action.dart';

final class UpdateExperienceGate extends StatelessWidget {
  const UpdateExperienceGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UpdateController>();
    if (!controller.initialized) return child;
    if (controller.mandatoryEnforced && controller.state.isOnline) {
      return _MandatoryUpdateScreen(controller: controller);
    }
    final upgrade = controller.upgradeReleases;
    if (upgrade.isNotEmpty) {
      return ReleaseStoryScreen(
        releases: upgrade,
        isUpgrade: true,
        onClose: controller.dismissUpgradeStory,
      );
    }
    if (!controller.state.isOnline && controller.hasExpiredMandatoryCandidate) {
      return Column(
        children: [
          MaterialBanner(
            leading: const Icon(Icons.warning_amber_rounded),
            content: Text(context.l10n.updateOfflineMandatoryWarning),
            actions: [
              TextButton(
                onPressed: controller.handleResume,
                child: Text(context.l10n.updateCheckNow),
              ),
            ],
          ),
          Expanded(child: child),
        ],
      );
    }
    final candidate = controller.state.candidate;
    if (candidate != null && controller.shouldShowAvailableStory) {
      return ReleaseStoryScreen(
        releases: [candidate.release],
        isUpgrade: false,
        controller: controller,
        onClose: controller.markAvailableStoryPresented,
      );
    }
    return child;
  }
}

final class _MandatoryUpdateScreen extends StatelessWidget {
  const _MandatoryUpdateScreen({required this.controller});

  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final release = state.candidate!.release;
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Icon(
                    Icons.system_security_update_warning_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.updateMandatoryTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.updateMandatoryBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    release.presentationFor(language)?.summary ??
                        context.l10n.releaseStoryFallbackSummary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (state.phase == UpdatePhase.downloading) ...[
                    LinearProgressIndicator(value: state.progress),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.updateStatusDownloading(
                        (state.progress * 100).round(),
                      ),
                    ),
                  ] else if (state.phase == UpdatePhase.verifying) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(context.l10n.updateStatusVerifying),
                  ] else if (state.phase == UpdatePhase.installing)
                    Text(context.l10n.updateStatusInstalling)
                  else
                    FilledButton.icon(
                      onPressed:
                          const {
                            UpdatePhase.ready,
                            UpdatePhase.restartRequired,
                          }.contains(state.phase)
                          ? () => requestUpdateInstall(context, controller)
                          : controller.download,
                      icon: Icon(
                        const {
                              UpdatePhase.ready,
                              UpdatePhase.restartRequired,
                            }.contains(state.phase)
                            ? Icons.install_mobile_rounded
                            : Icons.download_rounded,
                      ),
                      label: Text(
                        state.phase == UpdatePhase.restartRequired
                            ? context.l10n.updateRestart
                            : state.phase == UpdatePhase.ready
                            ? context.l10n.updateInstall
                            : context.l10n.updateDownload,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
