import 'package:flutter/material.dart';

import '../../application/app_block_onboarding_controller.dart';
import '../../domain/app_block_rule.dart';
import 'app_block_onboarding_page.dart';

final class DistractionSelectionPage extends StatefulWidget {
  const DistractionSelectionPage({required this.controller, super.key});

  final AppBlockOnboardingController controller;

  @override
  State<DistractionSelectionPage> createState() =>
      _DistractionSelectionPageState();
}

final class _DistractionSelectionPageState
    extends State<DistractionSelectionPage> {
  late Set<String> _selected;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.state.selectedPackages.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.controller.candidates;
    final allApps = widget.controller.installedApps;
    final insufficient = candidates.isEmpty;
    final rows = _showAll || insufficient
        ? allApps
              .map(
                (app) => (
                  packageName: app.packageName,
                  appName: app.appName,
                  detail: 'Installed app',
                ),
              )
              .toList(growable: false)
        : candidates
              .take(5)
              .map(
                (candidate) => (
                  packageName: candidate.packageName,
                  appName: candidate.appName,
                  detail: _candidateDetail(
                    candidate.foregroundDuration,
                    candidate.category,
                  ),
                ),
              )
              .toList(growable: false);

    return AppBlockOnboardingPage(
      title: 'What pulls you away most often?',
      subtitle: insufficient
          ? 'There is not enough usage data for meaningful suggestions. Choose apps manually.'
          : 'Possible distractions based on recent on-device usage. Nothing is selected for you.',
      body: Column(
        children: <Widget>[
          for (final row in rows)
            CheckboxListTile(
              key: Key('app-block-app-${row.packageName}'),
              value: _selected.contains(row.packageName),
              onChanged: (selected) =>
                  _toggle(row.packageName, selected ?? false),
              title: Text(row.appName),
              subtitle: Text(row.detail),
              secondary: const Icon(Icons.apps_rounded),
            ),
          if (!insufficient && !_showAll)
            TextButton.icon(
              key: const Key('app-block-show-all-apps'),
              onPressed: () => setState(() => _showAll = true),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Choose another app'),
            ),
        ],
      ),
      primary: FilledButton(
        key: const Key('app-block-confirm-selection'),
        onPressed: _selected.isEmpty
            ? null
            : () async {
                await widget.controller.setSelectedPackages(_selected);
                await widget.controller.bindAll(const GeneralRequirement());
              },
        child: Text(
          _selected.length == 1
              ? 'Protect 1 app'
              : 'Protect ${_selected.length} apps',
        ),
      ),
      secondary: TextButton(
        onPressed: widget.controller.defer,
        child: const Text('Maybe later'),
      ),
    );
  }

  void _toggle(String packageName, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(packageName);
      } else {
        _selected.remove(packageName);
      }
    });
    widget.controller.setSelectedPackages(_selected);
  }

  static String _candidateDetail(Duration usage, String? category) {
    final hours = usage.inMinutes ~/ 60;
    final minutes = usage.inMinutes % 60;
    final duration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    return category == null ? duration : '$duration · $category';
  }
}
