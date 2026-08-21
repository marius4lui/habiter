import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/components.dart';
import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../../../models/habit.dart';
import '../../../providers/habit_provider.dart';
import '../domain/widget_configuration.dart';
import '../domain/widget_configuration_gateway.dart';
import '../domain/widget_bridge.dart';
import 'widget_basic_editor.dart';
import 'widget_promotion_card.dart';

class WidgetManagementScreen extends StatefulWidget {
  const WidgetManagementScreen({
    super.key,
    this.gateway,
    this.habits,
    this.widgetBridge,
  });

  final WidgetConfigurationGateway? gateway;
  final List<Habit>? habits;
  final WidgetBridge? widgetBridge;

  @override
  State<WidgetManagementScreen> createState() => _WidgetManagementScreenState();
}

class _WidgetManagementScreenState extends State<WidgetManagementScreen> {
  late WidgetConfigurationGateway _gateway;
  Future<List<WidgetInstance>>? _instances;
  int? _configurationLaunchId;
  bool _configurationLaunchResolved = false;
  bool _openedConfigurationLaunch = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_instances != null) return;
    _gateway = widget.gateway ?? context.read<WidgetConfigurationGateway>();
    _instances = _load();
  }

  Future<List<WidgetInstance>> _load() async {
    final results = await Future.wait<Object?>(<Future<Object?>>[
      _gateway.listWidgetInstances(),
      _gateway.pendingWidgetConfiguration(),
    ]);
    if (mounted) {
      setState(() {
        _configurationLaunchId = results[1] as int?;
        _configurationLaunchResolved = true;
      });
    }
    return results[0]! as List<WidgetInstance>;
  }

  void _reload() {
    setState(() => _instances = _gateway.listWidgetInstances());
  }

  Future<void> _openEditor(
    WidgetInstance instance,
    List<WidgetInstance> instances,
  ) async {
    final configurationLaunch = _configurationLaunchId == instance.widgetId;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WidgetBasicEditor(
          instance: instance,
          habits: widget.habits ?? context.read<HabitProvider>().habits,
          gateway: _gateway,
          otherInstances: instances
              .where((candidate) => candidate.widgetId != instance.widgetId)
              .toList(growable: false),
          configurationLaunch: configurationLaunch,
        ),
      ),
    );
    if (mounted && !configurationLaunch) _reload();
  }

  void _openPendingConfiguration(List<WidgetInstance> instances) {
    if (_openedConfigurationLaunch || _configurationLaunchId == null) return;
    final matching = instances
        .where((instance) => instance.widgetId == _configurationLaunchId)
        .firstOrNull;
    if (matching == null) return;
    _openedConfigurationLaunch = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_openEditor(matching, instances));
    });
  }

  Future<void> _cancelConfigurationLaunch() async {
    if (_configurationLaunchId != null) {
      await _gateway.cancelWidgetConfiguration();
      return;
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _addWidget() async {
    final result = await requestWidgetPin(
      context,
      widget.widgetBridge ?? context.read<WidgetBridge>(),
    );
    if (mounted && result == WidgetPinResult.pinned) _reload();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _configurationLaunchId == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_cancelConfigurationLaunch());
    },
    child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _cancelConfigurationLaunch),
        title: Text(context.l10n.widgetInstancesTitle),
      ),
      floatingActionButton:
          _configurationLaunchResolved && _configurationLaunchId == null
          ? FloatingActionButton.extended(
              onPressed: _addWidget,
              icon: const Icon(Icons.add_to_home_screen_rounded),
              label: Text(context.l10n.widgetAddAnother),
            )
          : null,
      body: FutureBuilder<List<WidgetInstance>>(
        future: _instances,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _WidgetLoadFailure(onRetry: _reload);
          }
          final instances = snapshot.data ?? const <WidgetInstance>[];
          _openPendingConfiguration(instances);
          return HabiterContent(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                HabiterPageIntro(
                  title: context.l10n.widgetInstancesTitle,
                  subtitle: context.l10n.widgetInstancesBody,
                ),
                const SizedBox(height: HabiterSpace.lg),
                if (instances.isEmpty)
                  HabiterSurface(
                    child: Column(
                      children: <Widget>[
                        const Icon(Icons.widgets_outlined, size: 40),
                        const SizedBox(height: HabiterSpace.sm),
                        Text(
                          context.l10n.widgetInstancesEmpty,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...instances.map(
                    (instance) => Padding(
                      padding: const EdgeInsets.only(bottom: HabiterSpace.md),
                      child: _WidgetInstanceCard(
                        instance: instance,
                        onTap: () => _openEditor(instance, instances),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _WidgetInstanceCard extends StatelessWidget {
  const _WidgetInstanceCard({required this.instance, required this.onTap});

  final WidgetInstance instance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = instance.configuration.displayName?.trim();
    return HabiterSurface(
      padding: EdgeInsets.zero,
      child: ListTile(
        key: Key('widget-instance-${instance.widgetId}'),
        contentPadding: const EdgeInsets.all(HabiterSpace.md),
        leading: const CircleAvatar(child: Icon(Icons.widgets_rounded)),
        title: Text(
          name == null || name.isEmpty
              ? context.l10n.widgetDefaultName(instance.widgetId)
              : name,
        ),
        subtitle: Text(
          '${instance.widthDp} × ${instance.heightDp} dp · '
          '${_breakpointLabel(context, instance.breakpoint)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _WidgetLoadFailure extends StatelessWidget {
  const _WidgetLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(HabiterSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.sync_problem_rounded, size: 40),
          const SizedBox(height: HabiterSpace.sm),
          Text(context.l10n.widgetInstancesLoadFailed),
          const SizedBox(height: HabiterSpace.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    ),
  );
}

String _breakpointLabel(BuildContext context, WidgetBreakpoint value) =>
    switch (value) {
      WidgetBreakpoint.compact => context.l10n.widgetBreakpointCompact,
      WidgetBreakpoint.compactSquare =>
        context.l10n.widgetBreakpointCompactSquare,
      WidgetBreakpoint.wide => context.l10n.widgetBreakpointWide,
      WidgetBreakpoint.mediumHero => context.l10n.widgetBreakpointMediumHero,
      WidgetBreakpoint.large => context.l10n.widgetBreakpointLarge,
      WidgetBreakpoint.extraLarge => context.l10n.widgetBreakpointExtraLarge,
    };
