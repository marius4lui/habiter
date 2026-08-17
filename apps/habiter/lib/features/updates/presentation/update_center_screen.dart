import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/components.dart';
import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/update_controller.dart';
import '../domain/update_models.dart';
import '../domain/update_policy.dart';
import '../domain/update_state.dart';
import 'release_story_screen.dart';
import 'update_install_action.dart';

final class UpdateCenterScreen extends StatelessWidget {
  const UpdateCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UpdateController>();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.updateCenterTitle)),
      body: ListView(
        key: const Key('update-center'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          HabiterPageIntro(
            title: context.l10n.updateCenterTitle,
            subtitle: context.l10n.updatePrivacyNote,
          ),
          const SizedBox(height: HabiterSpace.lg),
          _StatusCard(controller: controller),
          const SizedBox(height: HabiterSpace.lg),
          _Section(
            title: context.l10n.updateTrackTitle,
            child: SegmentedButton<UpdateTrack>(
              segments: [
                ButtonSegment(
                  value: UpdateTrack.stable,
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(context.l10n.updateTrackStable),
                  tooltip: context.l10n.updateTrackStableBody,
                ),
                ButtonSegment(
                  value: UpdateTrack.beta,
                  icon: const Icon(Icons.science_outlined),
                  label: Text(context.l10n.updateTrackBeta),
                  tooltip: context.l10n.updateTrackBetaBody,
                ),
              ],
              selected: {controller.track},
              onSelectionChanged: (value) => controller.setTrack(value.single),
            ),
          ),
          _Section(
            title: context.l10n.updateProfileTitle,
            child: RadioGroup<UpdateProfile>(
              groupValue: controller.profile,
              onChanged: (value) {
                if (value != null) controller.setProfile(value);
              },
              child: Column(
                children: [
                  _ProfileTile(
                    value: UpdateProfile.immediate,
                    title: context.l10n.updateProfileImmediate,
                    body: context.l10n.updateProfileImmediateBody,
                  ),
                  _ProfileTile(
                    value: UpdateProfile.balanced,
                    title: context.l10n.updateProfileBalanced,
                    body: context.l10n.updateProfileBalancedBody,
                  ),
                  _ProfileTile(
                    value: UpdateProfile.saver,
                    title: context.l10n.updateProfileSaver,
                    body: context.l10n.updateProfileSaverBody,
                  ),
                ],
              ),
            ),
          ),
          _ReleaseHistory(controller: controller),
          _UpdateStorage(controller: controller),
        ],
      ),
    );
  }
}

final class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller});

  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final candidate = state.candidate;
    return HabiterSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_statusIcon(state.phase), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.updateStatusTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(_statusText(context, state)),
                  ],
                ),
              ),
            ],
          ),
          if (state.phase == UpdatePhase.downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: state.progress),
          ],
          const SizedBox(height: 16),
          Text(
            state.lastCheckedAt == null
                ? context.l10n.updateNeverChecked
                : context.l10n.updateLastChecked(
                    DateFormat.yMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).add_Hm().format(state.lastCheckedAt!.toLocal()),
                  ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('check-for-updates'),
                onPressed: controller.canCheck
                    ? () => controller.check(UpdateCheckTrigger.manual)
                    : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.updateCheckNow),
              ),
              if (candidate != null)
                OutlinedButton.icon(
                  onPressed: () => _openStory(context, controller),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(context.l10n.updateViewWhatsNew),
                ),
              if (candidate != null &&
                  state.phase != UpdatePhase.downloading &&
                  state.phase != UpdatePhase.verifying)
                OutlinedButton.icon(
                  onPressed: state.phase == UpdatePhase.ready
                      ? () => requestUpdateInstall(context, controller)
                      : controller.download,
                  icon: Icon(
                    state.phase == UpdatePhase.ready
                        ? Icons.install_mobile_rounded
                        : Icons.download_rounded,
                  ),
                  label: Text(
                    state.phase == UpdatePhase.ready
                        ? context.l10n.updateInstall
                        : controller.runtime?.supportsDirectInstall == true
                        ? context.l10n.updateDownload
                        : context.l10n.updateOpenDownload,
                  ),
                ),
            ],
          ),
          if (controller.runtime?.supportsUpdates == false) ...[
            const SizedBox(height: 12),
            Text(context.l10n.updateUnsupported),
          ],
        ],
      ),
    );
  }

  Future<void> _openStory(
    BuildContext context,
    UpdateController controller,
  ) async {
    final release = controller.state.candidate?.release;
    if (release == null) return;
    await controller.markAvailableStoryPresented();
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: ReleaseStoryScreen(
            releases: [release],
            isUpgrade: false,
            controller: controller,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

final class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.value,
    required this.title,
    required this.body,
  });

  final UpdateProfile value;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => RadioListTile<UpdateProfile>(
    contentPadding: EdgeInsets.zero,
    value: value,
    title: Text(title),
    subtitle: Text(body),
  );
}

final class _ReleaseHistory extends StatelessWidget {
  const _ReleaseHistory({required this.controller});

  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    final releases =
        controller.manifest?.releases.where(
          (release) =>
              controller.track == UpdateTrack.beta ||
              release.channel == ReleaseChannel.stable,
        ) ??
        const Iterable<UpdateRelease>.empty();
    return _Section(
      title: context.l10n.updateHistoryTitle,
      child: Column(
        children: [
          for (final release in releases.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                release.channel == ReleaseChannel.beta
                    ? Icons.science_outlined
                    : Icons.verified_outlined,
              ),
              title: Text('Habiter ${release.version}'),
              subtitle: Text(
                release
                        .presentationFor(
                          Localizations.localeOf(context).languageCode,
                        )
                        ?.summary ??
                    release.notes.all.firstOrNull ??
                    '',
              ),
            ),
        ],
      ),
    );
  }
}

final class _UpdateStorage extends StatefulWidget {
  const _UpdateStorage({required this.controller});

  final UpdateController controller;

  @override
  State<_UpdateStorage> createState() => _UpdateStorageState();
}

class _UpdateStorageState extends State<_UpdateStorage> {
  late Future<int> _downloads;

  @override
  void initState() {
    super.initState();
    _downloads = widget.controller.storedDownloadBytes();
  }

  void _refresh() {
    setState(() => _downloads = widget.controller.storedDownloadBytes());
  }

  @override
  Widget build(BuildContext context) => _Section(
    title: context.l10n.updateStorageTitle,
    child: FutureBuilder<int>(
      future: _downloads,
      builder: (context, snapshot) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.updateStorageUsage(
              _bytes(widget.controller.cachedMetadataBytes),
              _bytes(snapshot.data ?? 0),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () async {
                  await widget.controller.clearDownloads();
                  _refresh();
                },
                child: Text(context.l10n.updateClearDownloads),
              ),
              OutlinedButton(
                onPressed: widget.controller.clearManifestCache,
                child: Text(context.l10n.updateClearCache),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HabiterSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

String _statusText(BuildContext context, UpdateState state) =>
    switch (state.phase) {
      UpdatePhase.idle => context.l10n.updateStatusIdle,
      UpdatePhase.checking => context.l10n.updateStatusChecking,
      UpdatePhase.upToDate => context.l10n.updateStatusCurrent,
      UpdatePhase.available => context.l10n.updateStatusAvailable(
        state.candidate?.release.version ?? '',
      ),
      UpdatePhase.downloading => context.l10n.updateStatusDownloading(
        (state.progress * 100).round(),
      ),
      UpdatePhase.verifying => context.l10n.updateStatusVerifying,
      UpdatePhase.ready => context.l10n.updateStatusReady,
      UpdatePhase.installing => context.l10n.updateStatusInstalling,
      UpdatePhase.mandatory => context.l10n.updateStatusMandatory,
      UpdatePhase.error => context.l10n.updateStatusError,
    };

IconData _statusIcon(UpdatePhase phase) => switch (phase) {
  UpdatePhase.checking || UpdatePhase.verifying => Icons.sync_rounded,
  UpdatePhase.upToDate => Icons.verified_rounded,
  UpdatePhase.available || UpdatePhase.mandatory => Icons.new_releases_rounded,
  UpdatePhase.downloading => Icons.downloading_rounded,
  UpdatePhase.ready => Icons.install_mobile_rounded,
  UpdatePhase.installing => Icons.open_in_new_rounded,
  UpdatePhase.error => Icons.cloud_off_rounded,
  UpdatePhase.idle => Icons.system_update_alt_rounded,
};

String _bytes(int value) {
  if (value < 1024) return '$value B';
  if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
