import 'package:flutter/material.dart';

import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';

class WidgetPreview extends StatefulWidget {
  const WidgetPreview({
    super.key,
    this.animate = true,
    this.habitName,
    this.habitIcon,
  });

  final bool animate;
  final String? habitName;
  final String? habitIcon;

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
    final habitName = widget.habitName ?? context.l10n.templateWorkout;
    final habitIcon = widget.habitIcon ?? '🏋️';
    return Semantics(
      label: context.l10n.widgetPreviewSemantics,
      image: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(HabiterRadius.prominent),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
          ),
        ),
        child: SizedBox(
          height: 286,
          child: Padding(
            padding: const EdgeInsets.all(HabiterSpace.sm2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final minWidth = availableWidth < 190 ? availableWidth : 190.0;
                final maxWidth = availableWidth < 292 ? availableWidth : 292.0;
                return Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = Curves.easeInOutCubic.transform(
                        _controller.value,
                      );
                      return MediaQuery(
                        // This remains a launcher-widget illustration. The
                        // surrounding copy and controls still honor text scale.
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.noScaling),
                        child: Container(
                          width: minWidth + ((maxWidth - minWidth) * t),
                          height: 120 + (t * 72),
                          padding: const EdgeInsets.all(HabiterSpace.md),
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              theme.colorScheme.onSurface.withValues(
                                alpha: 0.04,
                              ),
                              theme.colorScheme.surface,
                            ),
                            borderRadius: BorderRadius.circular(
                              HabiterRadius.card,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.42,
                              ),
                              width: 2,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(
                                  alpha: 0.13,
                                ),
                                blurRadius: 26,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Text(
                                    context.l10n.today.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '1 / 3',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: HabiterSpace.sm),
                              LinearProgressIndicator(
                                value: 1 / 3,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(
                                  HabiterRadius.pill,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: <Widget>[
                                  Text(
                                    habitIcon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: HabiterSpace.sm),
                                  Expanded(
                                    child: Text(
                                      habitName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  if (t > .35)
                                    Container(
                                      width: 38,
                                      height: 38,
                                      margin: const EdgeInsetsDirectional.only(
                                        start: HabiterSpace.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: theme.colorScheme.onPrimary,
                                        size: 21,
                                      ),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
