import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../widgets/domain/widget_bridge.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../onboarding_scaffold.dart';

enum _PinView { ready, requesting, pinned, declined, unsupported, failed }

class WidgetPinStep extends StatefulWidget {
  const WidgetPinStep({
    super.key,
    required this.controller,
    required this.bridge,
  });

  final OnboardingController controller;
  final WidgetBridge bridge;

  @override
  State<WidgetPinStep> createState() => _WidgetPinStepState();
}

class _WidgetPinStepState extends State<WidgetPinStep> {
  _PinView _view = _PinView.ready;

  Future<void> _request() async {
    setState(() => _view = _PinView.requesting);
    await widget.controller.recordWidgetPinAttempt();
    try {
      if (!await widget.bridge.isPinningSupported()) {
        if (mounted) setState(() => _view = _PinView.unsupported);
        return;
      }
      final result = await widget.bridge.requestPin();
      if (!mounted) return;
      setState(() {
        _view = switch (result) {
          WidgetPinResult.pinned => _PinView.pinned,
          WidgetPinResult.declined ||
          WidgetPinResult.requested => _PinView.declined,
          WidgetPinResult.unsupported => _PinView.unsupported,
          WidgetPinResult.failed => _PinView.failed,
        };
      });
    } catch (_) {
      if (mounted) setState(() => _view = _PinView.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manual = _view == _PinView.unsupported || _view == _PinView.failed;
    final pinned = _view == _PinView.pinned;
    return OnboardingScaffold(
      step: OnboardingStep.widgetPin,
      title: pinned
          ? context.l10n.onboardingWidgetReadyTitle
          : manual
          ? context.l10n.onboardingWidgetManualTitle
          : context.l10n.onboardingWidgetPinTitle,
      subtitle: pinned
          ? context.l10n.onboardingWidgetReadyBody
          : _view == _PinView.declined
          ? context.l10n.onboardingWidgetDeclinedBody
          : context.l10n.onboardingWidgetPinBody,
      onBack: _view == _PinView.requesting ? null : widget.controller.back,
      body: _body(context, manual: manual, pinned: pinned),
      primaryAction: FilledButton(
        onPressed: _view == _PinView.requesting
            ? null
            : pinned
            ? widget.controller.markWidgetPinned
            : (_view == _PinView.ready
                  ? _request
                  : widget.controller.finishWithoutPin),
        child: Text(
          pinned
              ? context.l10n.onboardingWidgetLetsGo
              : _view == _PinView.ready
              ? context.l10n.onboardingWidgetAdd
              : context.l10n.onboardingWidgetUnderstood,
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required bool manual,
    required bool pinned,
  }) {
    if (_view == _PinView.requesting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pinned) {
      return Center(
        child: Icon(
          Icons.check_circle_rounded,
          size: 96,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (manual) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            <Widget>[
                  Text('1. ${context.l10n.onboardingWidgetManualOne}'),
                  Text('2. ${context.l10n.onboardingWidgetManualTwo}'),
                  Text('3. ${context.l10n.onboardingWidgetManualThree}'),
                  Text('4. ${context.l10n.onboardingWidgetManualFour}'),
                ]
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: child,
                  ),
                )
                .toList(),
      );
    }
    return Center(
      child: Icon(
        Icons.widgets_rounded,
        size: 88,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
