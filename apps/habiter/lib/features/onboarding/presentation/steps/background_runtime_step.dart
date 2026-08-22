import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../runtime/application/background_runtime_reconciler.dart';
import '../../../runtime/domain/background_runtime_gateway.dart';
import '../../../runtime/infrastructure/method_channel_background_runtime_gateway.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../onboarding_scaffold.dart';

class BackgroundRuntimeStep extends StatefulWidget {
  const BackgroundRuntimeStep({
    super.key,
    required this.controller,
    this.gateway = const MethodChannelBackgroundRuntimeGateway(),
  });

  final OnboardingController controller;
  final BackgroundRuntimeGateway gateway;

  @override
  State<BackgroundRuntimeStep> createState() => _BackgroundRuntimeStepState();
}

class _BackgroundRuntimeStepState extends State<BackgroundRuntimeStep>
    with WidgetsBindingObserver {
  BackgroundRuntimeSnapshot? _snapshot;
  bool _loading = true;
  bool _openingSettings = false;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh(reconcile: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh(reconcile: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return OnboardingScaffold(
      step: OnboardingStep.backgroundRuntime,
      title: context.l10n.onboardingBackgroundTitle,
      subtitle: context.l10n.onboardingBackgroundBody,
      onBack: _loading ? null : widget.controller.back,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(HabiterRadius.prominent),
            ),
            child: Column(
              children: <Widget>[
                _StatusRow(
                  key: const Key('background-notification-status'),
                  icon: Icons.notifications_active_outlined,
                  label: context.l10n.onboardingBackgroundNotifications,
                  value: snapshot?.notificationsGranted == true
                      ? context.l10n.onboardingBackgroundNotificationsReady
                      : context.l10n.onboardingBackgroundNotificationsNeeded,
                  ready: snapshot?.notificationsGranted == true,
                ),
                const Divider(height: 1),
                _StatusRow(
                  key: const Key('background-runtime-status'),
                  icon: Icons.sync_rounded,
                  label: context.l10n.onboardingBackgroundRuntime,
                  value: snapshot?.features.remindersEnabled == true
                      ? context.l10n.onboardingBackgroundRuntimeReady
                      : context.l10n.onboardingBackgroundRuntimePending,
                  ready: snapshot?.features.remindersEnabled == true,
                ),
                const Divider(height: 1),
                _StatusRow(
                  key: const Key('background-battery-status'),
                  icon: Icons.battery_saver_outlined,
                  label: context.l10n.onboardingBackgroundBattery,
                  value: snapshot?.batteryOptimized == false
                      ? context.l10n.onboardingBackgroundBatteryReady
                      : context.l10n.onboardingBackgroundBatteryReview,
                  ready: snapshot?.batteryOptimized == false,
                ),
              ],
            ),
          ),
          if (_loading) ...<Widget>[
            const SizedBox(height: HabiterSpace.md),
            const LinearProgressIndicator(minHeight: 4),
          ],
          if (_unavailable) ...<Widget>[
            const SizedBox(height: HabiterSpace.md),
            Text(
              context.l10n.onboardingBackgroundUnavailable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      primaryAction: FilledButton(
        key: const Key('background-runtime-continue'),
        onPressed: _loading ? null : _continue,
        child: Text(context.l10n.onboardingBackgroundContinue),
      ),
      secondaryAction: snapshot?.batteryOptimized == true
          ? TextButton(
              key: const Key('background-open-battery-settings'),
              onPressed: _openingSettings ? null : _openBatterySettings,
              child: Text(context.l10n.onboardingBackgroundOpenSettings),
            )
          : null,
    );
  }

  Future<void> _refresh({required bool reconcile}) async {
    if (!mounted) return;
    setState(() => _loading = true);
    var result = await widget.gateway.snapshot();
    if (reconcile &&
        result is BackgroundRuntimeSuccess<BackgroundRuntimeSnapshot>) {
      final snapshot = result.value;
      if (snapshot.notificationsGranted &&
          !snapshot.features.remindersEnabled) {
        await BackgroundRuntimeReconciler(
          widget.gateway,
        ).setRemindersEnabled(true);
        result = await widget.gateway.snapshot();
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result case BackgroundRuntimeSuccess<BackgroundRuntimeSnapshot>(
        :final value,
      )) {
        _snapshot = value;
        _unavailable = false;
      } else {
        _unavailable = true;
      }
    });
  }

  Future<void> _openBatterySettings() async {
    setState(() => _openingSettings = true);
    await widget.gateway.openBatterySettings();
    if (!mounted) return;
    setState(() => _openingSettings = false);
  }

  Future<void> _continue() async {
    final snapshot = _snapshot;
    if (snapshot?.notificationsGranted == true) {
      await BackgroundRuntimeReconciler(
        widget.gateway,
      ).setRemindersEnabled(true);
    }
    await widget.controller.completeBackgroundSetup();
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.ready,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ready;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(HabiterSpace.md),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 24),
        const SizedBox(width: HabiterSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(
          ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          color: ready
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    ),
  );
}
