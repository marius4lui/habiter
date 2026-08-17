import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/motion.dart';
import '../../../l10n/l10n.dart';
import '../application/update_controller.dart';
import '../domain/update_models.dart';
import 'update_install_action.dart';
import 'verified_release_image.dart';

final class ReleaseStoryScreen extends StatelessWidget {
  const ReleaseStoryScreen({
    required this.releases,
    required this.isUpgrade,
    required this.onClose,
    this.controller,
    super.key,
  });

  final List<UpdateRelease> releases;
  final bool isUpgrade;
  final VoidCallback onClose;
  final UpdateController? controller;

  @override
  Widget build(BuildContext context) {
    final primary = releases.first;
    final language = Localizations.localeOf(context).languageCode;
    final presentation = primary.presentationFor(language);
    final headline = isUpgrade
        ? context.l10n.releaseStorySuccessTitle
        : presentation?.headline ??
              context.l10n.releaseStoryFallbackHeadline(primary.version);
    final summary = isUpgrade
        ? context.l10n.releaseStorySuccessBody
        : presentation?.summary ?? context.l10n.releaseStoryFallbackSummary;
    final highlights = _highlights(language);
    final reducedMotion = context.reduceMotion;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _StoryHero(
                headline: headline,
                summary: summary,
                version: primary.version,
                isUpgrade: isUpgrade,
                reducedMotion: reducedMotion,
                onClose: onClose,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList.list(
                children: [
                  if (!isUpgrade) _DeadlineNotice(release: primary),
                  if (highlights.isNotEmpty) ...[
                    _HighlightGrid(items: highlights),
                    const SizedBox(height: 28),
                  ],
                  _Changes(releases: releases, language: language),
                  if (releases.length > 1) ...[
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.releaseStoryDetails,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    for (final release in releases)
                      _VersionDetails(release: release, language: language),
                  ],
                  const SizedBox(height: 28),
                  if (isUpgrade)
                    FilledButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(context.l10n.releaseStoryContinue),
                    )
                  else if (controller != null)
                    _StoryUpdateAction(controller: controller!),
                  if (!isUpgrade) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onClose,
                      child: Text(context.l10n.updateNotNow),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_StoryHighlight> _highlights(String language) {
    final items = <_StoryHighlight>[];
    final ids = <String>{};
    for (final release in releases) {
      for (final highlight
          in release.presentationFor(language)?.highlights ?? const []) {
        if (items.length == 5) return items;
        if (!ids.add('${release.buildNumber}:${highlight.id}')) continue;
        items.add(
          _StoryHighlight(
            highlight: highlight,
            media: highlight.mediaId == null
                ? null
                : release.media[highlight.mediaId],
          ),
        );
      }
    }
    return items;
  }
}

final class _StoryHero extends StatelessWidget {
  const _StoryHero({
    required this.headline,
    required this.summary,
    required this.version,
    required this.isUpgrade,
    required this.reducedMotion,
    required this.onClose,
  });

  final String headline;
  final String summary;
  final String version;
  final bool isUpgrade;
  final bool reducedMotion;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hero = Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.tertiaryContainer],
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 12,
            end: 12,
            child: IconButton.filledTonal(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 52, 28, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  isUpgrade
                      ? Icons.auto_awesome_rounded
                      : Icons.rocket_launch_rounded,
                  size: 54,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(height: 24),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Chip(label: Text('v$version')),
              ],
            ),
          ),
        ],
      ),
    );
    if (reducedMotion) return hero;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: HabiterMotion.emphasized.duration(reduced: false),
      curve: HabiterMotion.emphasized.curve,
      builder: (_, value, child) => Opacity(
        opacity: ((value - 0.96) / 0.04).clamp(0, 1),
        child: Transform.scale(scale: value, child: child),
      ),
      child: hero,
    );
  }
}

final class _StoryHighlight {
  const _StoryHighlight({required this.highlight, required this.media});

  final UpdateHighlight highlight;
  final ReleaseMedia? media;
}

final class _HighlightGrid extends StatelessWidget {
  const _HighlightGrid({required this.items});

  final List<_StoryHighlight> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaler = MediaQuery.textScalerOf(context).scale(1);
      final columns = constraints.maxWidth >= 700 && scaler <= 1.3 ? 2 : 1;
      final width = columns == 1
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: _HighlightCard(item: item),
            ),
        ],
      );
    },
  );
}

final class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.item});

  final _StoryHighlight item;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(
        _icon(item.highlight.icon),
        size: 44,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: item.media == null ? 100 : 150,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: VerifiedReleaseImage(
                media: item.media,
                fallback: fallback,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.highlight.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(item.highlight.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _Changes extends StatelessWidget {
  const _Changes({required this.releases, required this.language});

  final List<UpdateRelease> releases;
  final String language;

  @override
  Widget build(BuildContext context) {
    final notes = <String, List<String>>{
      context.l10n.releaseStoryAdded: [],
      context.l10n.releaseStoryChanged: [],
      context.l10n.releaseStoryFixed: [],
      context.l10n.releaseStorySecurity: [],
    };
    for (final release in releases) {
      final changes =
          release.presentationFor(language)?.changes ?? release.notes;
      notes[context.l10n.releaseStoryAdded]!.addAll(changes.added);
      notes[context.l10n.releaseStoryChanged]!.addAll(changes.changed);
      notes[context.l10n.releaseStoryFixed]!.addAll(changes.fixed);
      notes[context.l10n.releaseStorySecurity]!.addAll(changes.security);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in notes.entries)
          if (entry.value.isNotEmpty) ...[
            Text(entry.key, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final note in entry.value.toSet())
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(Icons.circle, size: 6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(note)),
                  ],
                ),
              ),
            const SizedBox(height: 18),
          ],
      ],
    );
  }
}

final class _VersionDetails extends StatelessWidget {
  const _VersionDetails({required this.release, required this.language});

  final UpdateRelease release;
  final String language;

  @override
  Widget build(BuildContext context) {
    final presentation = release.presentationFor(language);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Habiter ${release.version}'),
      subtitle: presentation == null ? null : Text(presentation.summary),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            (presentation?.changes ?? release.notes).all.join('\n\n'),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }
}

final class _DeadlineNotice extends StatefulWidget {
  const _DeadlineNotice({required this.release});

  final UpdateRelease release;

  @override
  State<_DeadlineNotice> createState() => _DeadlineNoticeState();
}

final class _DeadlineNoticeState extends State<_DeadlineNotice> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.release.mandatoryAfter != null) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.release.mandatoryAfter;
    if (deadline == null || !deadline.isAfter(DateTime.now())) {
      return const SizedBox.shrink();
    }
    final remainingMinutes = deadline.difference(DateTime.now()).inMinutes;
    final hours = math.max(1, (remainingMinutes / 60).ceil());
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(context.l10n.updateMandatoryCountdown(hours)),
        ),
      ),
    );
  }
}

final class _StoryUpdateAction extends StatelessWidget {
  const _StoryUpdateAction({required this.controller});

  final UpdateController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    if (state.phase == UpdatePhase.downloading) {
      return Column(
        children: [
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: 8),
          Text(
            context.l10n.updateStatusDownloading(
              (state.progress * 100).round(),
            ),
          ),
        ],
      );
    }
    if (state.phase == UpdatePhase.verifying) {
      return const Center(child: CircularProgressIndicator());
    }
    final ready = state.phase == UpdatePhase.ready;
    final external = controller.runtime?.supportsDirectInstall != true;
    return FilledButton.icon(
      onPressed: () async {
        if (!ready) {
          await controller.download();
          return;
        }
        await requestUpdateInstall(context, controller);
      },
      icon: Icon(ready ? Icons.install_mobile_rounded : Icons.download_rounded),
      label: Text(
        ready
            ? context.l10n.updateInstall
            : external
            ? context.l10n.updateOpenDownload
            : context.l10n.updateDownload,
      ),
    );
  }
}

IconData _icon(String value) => switch (value) {
  'security' => Icons.verified_user_outlined,
  'speed' => Icons.bolt_rounded,
  'design' => Icons.auto_awesome_rounded,
  'download' => Icons.download_done_rounded,
  'history' => Icons.history_rounded,
  _ => Icons.new_releases_outlined,
};
