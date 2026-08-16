import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/components.dart';
import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../domain/widget_bridge.dart';
import 'widget_preview.dart';

class WidgetPromotionCard extends StatefulWidget {
  const WidgetPromotionCard({
    super.key,
    required this.bridge,
    required this.onDismiss,
    required this.onPinned,
  });

  final WidgetBridge bridge;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onPinned;

  @override
  State<WidgetPromotionCard> createState() => _WidgetPromotionCardState();
}

class _WidgetPromotionCardState extends State<WidgetPromotionCard> {
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    final result = await requestWidgetPin(context, widget.bridge);
    if (!mounted) return;
    if (result == WidgetPinResult.pinned) await widget.onPinned();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => HabiterSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.add_to_home_screen_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: HabiterSpace.sm2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.widgetPromotionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: HabiterSpace.xs),
                  Text(context.l10n.widgetPromotionBody),
                ],
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: _busy ? null : widget.onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: HabiterSpace.md),
        FilledButton.icon(
          onPressed: _busy ? null : _add,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.widgets_rounded),
          label: Text(context.l10n.onboardingWidgetAdd),
        ),
      ],
    ),
  );
}

Future<WidgetPinResult> requestWidgetPin(
  BuildContext context,
  WidgetBridge bridge,
) async {
  final supported = await bridge.isPinningSupported();
  if (!context.mounted) return WidgetPinResult.failed;
  if (!supported) {
    await _showManualInstructions(context);
    return WidgetPinResult.unsupported;
  }
  final result = await bridge.requestPin();
  if (!context.mounted) return result;
  final message = result == WidgetPinResult.pinned
      ? context.l10n.onboardingWidgetReadyBody
      : context.l10n.onboardingWidgetDeclinedBody;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  return result;
}

Future<void> showWidgetManagementDialog(BuildContext context) async {
  final bridge = context.read<WidgetBridge>();
  final onboarding = context.read<OnboardingController?>();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.widgetSettingsTitle),
      content: const SingleChildScrollView(
        child: WidgetPreview(animate: false),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(dialogContext);
            final result = await requestWidgetPin(context, bridge);
            if (result == WidgetPinResult.pinned) {
              await onboarding?.markWidgetPinned();
            }
          },
          icon: const Icon(Icons.add_to_home_screen_rounded),
          label: Text(context.l10n.onboardingWidgetAdd),
        ),
      ],
    ),
  );
}

Future<void> _showManualInstructions(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(context.l10n.onboardingWidgetManualTitle),
    content: Text(
      '1. ${context.l10n.onboardingWidgetManualOne}\n'
      '2. ${context.l10n.onboardingWidgetManualTwo}\n'
      '3. ${context.l10n.onboardingWidgetManualThree}\n'
      '4. ${context.l10n.onboardingWidgetManualFour}',
    ),
    actions: <Widget>[
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.onboardingWidgetUnderstood),
      ),
    ],
  ),
);
