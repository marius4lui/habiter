import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../widgets/domain/widget_bridge.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../components/habit_illustration.dart';
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
    final pinned = _view == _PinView.pinned;
    return OnboardingScaffold(
      step: OnboardingStep.widgetPin,
      title: _title(context),
      subtitle: _subtitle(context),
      onBack: _view == _PinView.requesting ? null : widget.controller.back,
      body: Semantics(
        container: true,
        liveRegion: _view != _PinView.ready,
        child: KeyedSubtree(
          key: ValueKey<String>('widget-pin-state-${_view.name}'),
          child: _body(context),
        ),
      ),
      primaryAction: FilledButton(
        onPressed: _view == _PinView.requesting
            ? null
            : pinned
            ? widget.controller.markWidgetPinned
            : _view == _PinView.ready
            ? _request
            : widget.controller.finishWithoutPin,
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

  String _title(BuildContext context) => switch (_view) {
    _PinView.ready => context.l10n.onboardingWidgetPinTitle,
    _PinView.requesting => context.l10n.onboardingWidgetRequestingTitle,
    _PinView.pinned => context.l10n.onboardingWidgetReadyTitle,
    _PinView.declined => context.l10n.onboardingWidgetDeclinedTitle,
    _PinView.unsupported ||
    _PinView.failed => context.l10n.onboardingWidgetManualTitle,
  };

  String _subtitle(BuildContext context) => switch (_view) {
    _PinView.ready => context.l10n.onboardingWidgetPinBody,
    _PinView.requesting => context.l10n.onboardingWidgetRequestingBody,
    _PinView.pinned => context.l10n.onboardingWidgetReadyBody,
    _PinView.declined => context.l10n.onboardingWidgetDeclinedBody,
    _PinView.unsupported => context.l10n.onboardingWidgetUnsupportedBody,
    _PinView.failed => context.l10n.onboardingWidgetFailedBody,
  };

  Widget _body(BuildContext context) => switch (_view) {
    _PinView.requesting => Column(
      children: <Widget>[
        HabitIllustration(
          kind: HabitIllustrationKind.widget,
          step: OnboardingStep.widgetPin,
          semanticLabel: context.l10n.onboardingWidgetRequestingTitle,
          height: 154,
        ),
        const SizedBox(height: HabiterSpace.md),
        const LinearProgressIndicator(minHeight: 4),
      ],
    ),
    _PinView.pinned => HabitIllustration(
      kind: HabitIllustrationKind.growth,
      step: OnboardingStep.widgetPin,
      semanticLabel: context.l10n.onboardingWidgetReadyTitle,
      height: 230,
    ),
    _PinView.unsupported || _PinView.failed => _manualSteps(context),
    _PinView.ready || _PinView.declined => HabitIllustration(
      kind: HabitIllustrationKind.widget,
      step: OnboardingStep.widgetPin,
      semanticLabel: _title(context),
      height: 230,
    ),
  };

  Widget _manualSteps(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      HabitIllustration(
        kind: HabitIllustrationKind.widget,
        step: OnboardingStep.widgetPin,
        semanticLabel: context.l10n.onboardingWidgetManualTitle,
        height: 120,
      ),
      const SizedBox(height: HabiterSpace.sm),
      _ManualStep(code: '01', label: context.l10n.onboardingWidgetManualOne),
      _ManualStep(code: '02', label: context.l10n.onboardingWidgetManualTwo),
      _ManualStep(code: '03', label: context.l10n.onboardingWidgetManualThree),
      _ManualStep(code: '04', label: context.l10n.onboardingWidgetManualFour),
    ],
  );
}

class _ManualStep extends StatelessWidget {
  const _ManualStep({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HabiterSpace.sm),
    child: Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(
        horizontal: HabiterSpace.md,
        vertical: HabiterSpace.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(HabiterRadius.card),
      ),
      child: Row(
        children: <Widget>[
          Text(
            code,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: HabiterSpace.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}
