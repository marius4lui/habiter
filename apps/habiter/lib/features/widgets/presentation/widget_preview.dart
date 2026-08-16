import 'package:flutter/material.dart';

import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';

class WidgetPreview extends StatefulWidget {
  const WidgetPreview({super.key, this.animate = true});

  final bool animate;

  @override
  State<WidgetPreview> createState() => _WidgetPreviewState();
}

class _WidgetPreviewState extends State<WidgetPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = .6;
    } else if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: context.l10n.widgetPreviewSemantics,
      image: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(HabiterRadius.prominent),
        ),
        child: SizedBox(
          height: 300,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_controller.value);
                return MediaQuery(
                  // This is an illustrative image of an Android widget. Keep
                  // its simulated launcher typography at a realistic scale;
                  // the surrounding copy and controls still honor large text.
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.noScaling),
                  child: Container(
                    width: 180 + (t * 110),
                    height: 112 + (t * 82),
                    padding: const EdgeInsets.all(HabiterSpace.md),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(HabiterRadius.card),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: .65,
                        ),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.14,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              context.l10n.today,
                              style: theme.textTheme.labelLarge,
                            ),
                            const Spacer(),
                            Text('1 / 3', style: theme.textTheme.labelLarge),
                          ],
                        ),
                        const SizedBox(height: HabiterSpace.sm),
                        LinearProgressIndicator(
                          value: 1 / 3,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        const Spacer(),
                        Row(
                          children: <Widget>[
                            const Text('🏋️', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: HabiterSpace.sm),
                            Expanded(
                              child: Text(
                                context.l10n.templateWorkout,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            if (t > .35)
                              const FilledButton.tonal(
                                onPressed: null,
                                child: Icon(Icons.check_rounded),
                              ),
                          ],
                        ),
                        if (t > .65) ...<Widget>[
                          const SizedBox(height: HabiterSpace.sm),
                          Text(
                            context.l10n.widgetPreviewNext(
                              context.l10n.templateRead,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
