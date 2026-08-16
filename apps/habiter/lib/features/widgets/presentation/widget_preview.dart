import 'package:flutter/material.dart';

import '../../../core/design_system/tokens.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Habiter home screen widget preview',
      image: true,
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
                return Container(
                  width: 180 + (t * 110),
                  height: 112 + (t * 82),
                  padding: const EdgeInsets.all(HabiterSpace.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(HabiterRadius.card),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.14),
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
                          Text('Today', style: theme.textTheme.labelLarge),
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
                              'Training',
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
                          'Next: Read',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
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
