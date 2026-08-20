import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/haptics.dart';
import '../../../core/design_system/motion.dart';
import '../../../l10n/l10n.dart';
import '../application/habit_hub_model.dart';

final class _PreviousDestinationIntent extends Intent {
  const _PreviousDestinationIntent();
}

final class _NextDestinationIntent extends Intent {
  const _NextDestinationIntent();
}

final class _OpenDestinationIntent extends Intent {
  const _OpenDestinationIntent();
}

class HabitNavigationWheel extends StatefulWidget {
  const HabitNavigationWheel({
    super.key,
    required this.onOpen,
    this.onSelectionChanged,
    this.initialDestination = HabitHubDestination.today,
  });

  final ValueChanged<HabitHubDestination> onOpen;
  final ValueChanged<HabitHubDestination>? onSelectionChanged;
  final HabitHubDestination initialDestination;

  @override
  State<HabitNavigationWheel> createState() => _HabitNavigationWheelState();
}

class _HabitNavigationWheelState extends State<HabitNavigationWheel>
    with SingleTickerProviderStateMixin {
  static const _dragExtent = 142.0;
  late final AnimationController _position;
  late final FocusNode _focusNode;
  late int _settledIndex;

  int get _count => habitHubDestinations.length;
  int get _nearestIndex => _normalize(_position.value.round());

  @override
  void initState() {
    super.initState();
    _settledIndex = habitHubDestinations.indexOf(widget.initialDestination);
    _focusNode = FocusNode(debugLabel: 'Habit navigation wheel');
    _position = AnimationController.unbounded(
      vsync: this,
      value: _settledIndex.toDouble(),
    )..addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant HabitNavigationWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDestination == widget.initialDestination) return;
    final target = habitHubDestinations.indexOf(widget.initialDestination);
    _position.value = target.toDouble();
    _settledIndex = target;
  }

  @override
  void dispose() {
    _position
      ..removeListener(_rebuild)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selected = habitHubDestinations[_nearestIndex];
    return FocusTraversalGroup(
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowLeft):
              _PreviousDestinationIntent(),
          SingleActivator(LogicalKeyboardKey.arrowRight):
              _NextDestinationIntent(),
          SingleActivator(LogicalKeyboardKey.enter): _OpenDestinationIntent(),
          SingleActivator(LogicalKeyboardKey.space): _OpenDestinationIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _PreviousDestinationIntent:
                CallbackAction<_PreviousDestinationIntent>(
                  onInvoke: (_) {
                    _selectRaw(_position.value.round() - 1);
                    return null;
                  },
                ),
            _NextDestinationIntent: CallbackAction<_NextDestinationIntent>(
              onInvoke: (_) {
                _selectRaw(_position.value.round() + 1);
                return null;
              },
            ),
            _OpenDestinationIntent: CallbackAction<_OpenDestinationIntent>(
              onInvoke: (_) {
                widget.onOpen(habitHubDestinations[_settledIndex]);
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: _focusNode,
            child: Semantics(
              container: true,
              label: context.l10n.habitHubWheelPosition(
                _label(context, selected),
                _nearestIndex + 1,
                _count,
              ),
              child: SizedBox(
                key: const Key('habit-navigation-wheel'),
                height: 270,
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      _focusNode.requestFocus();
                      _position.stop();
                    },
                    onHorizontalDragUpdate: (details) {
                      _position.value -= details.delta.dx / _dragExtent;
                    },
                    onHorizontalDragEnd: _settleAfterDrag,
                    onHorizontalDragCancel: _snapToNearest,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _WheelBed(dark: _isDark(context)),
                        ..._cards(context, constraints.maxWidth),
                        _OpenButton(
                          top:
                              (constraints.maxWidth * .43).clamp(138.0, 172.0) *
                                  .94 +
                              12,
                          label: context.l10n.habitHubOpenDestination(
                            _label(
                              context,
                              habitHubDestinations[_settledIndex],
                            ),
                          ),
                          icon: _icon(habitHubDestinations[_settledIndex]),
                          onPressed: () => widget.onOpen(
                            habitHubDestinations[_settledIndex],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _cards(BuildContext context, double width) {
    final cardWidth = (width * .43).clamp(138.0, 172.0);
    final cardHeight = cardWidth * .94;
    final radius = (width * 1.04).clamp(330.0, 430.0);
    final ordered = List<int>.generate(_count, (index) => index)
      ..sort((a, b) => _deltaFor(b).abs().compareTo(_deltaFor(a).abs()));

    return <Widget>[
      for (final index in ordered)
        if (_deltaFor(index).abs() < 2.45)
          _card(
            context,
            index: index,
            width: width,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            radius: radius,
          ),
    ];
  }

  Widget _card(
    BuildContext context, {
    required int index,
    required double width,
    required double cardWidth,
    required double cardHeight,
    required double radius,
  }) {
    final destination = habitHubDestinations[index];
    final delta = _deltaFor(index);
    final angle = delta * .36;
    final focus = (1 - delta.abs()).clamp(0.0, 1.0);
    final depth = (1 - delta.abs() / 2.45).clamp(0.0, 1.0);
    final easedFocus = Curves.easeOutCubic.transform(focus);
    final scale = .84 + easedFocus * .16;
    final left = width / 2 + math.sin(angle) * radius - cardWidth / 2;
    final top = -10 + (1 - math.cos(angle)) * radius * .62;
    final selected = index == _nearestIndex;
    final label = _label(context, destination);
    final paper = _paperColor(context, destination);
    final dark = _isDark(context);

    return Positioned(
      left: left,
      top: top,
      width: cardWidth,
      height: cardHeight,
      child: Opacity(
        opacity: .66 + depth * .34,
        child: Transform.rotate(
          angle: delta * .13,
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: Semantics(
              button: true,
              selected: selected,
              label: context.l10n.habitHubWheelPosition(
                label,
                index + 1,
                _count,
              ),
              onTap: () => _onCardTap(index),
              child: ExcludeSemantics(
                child: AnimatedContainer(
                  key: Key('hub-wheel-card-${destination.name}'),
                  duration: context.reduceMotion
                      ? Duration.zero
                      : HabiterMotion.quick.normal,
                  curve: HabiterMotion.quick.curve,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? <Color>[
                              Color.lerp(paper, Colors.white, .055)!,
                              Color.lerp(paper, Colors.black, .045)!,
                            ]
                          : <Color>[
                              Color.lerp(paper, Colors.white, .68)!,
                              paper,
                            ],
                    ),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: selected ? .20 : .11)
                          : Colors.white.withValues(
                              alpha: selected ? .96 : .72,
                            ),
                      width: selected ? 1.4 : 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: selected ? .17 : .07,
                        ),
                        blurRadius: selected ? 24 : 12,
                        offset: Offset(0, selected ? 12 : 7),
                      ),
                      if (selected)
                        BoxShadow(
                          color: _iconColor(
                            destination,
                          ).withValues(alpha: dark ? .12 : .18),
                          blurRadius: 30,
                          spreadRadius: -8,
                        ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onCardTap(index),
                      splashColor: _iconColor(
                        destination,
                      ).withValues(alpha: .16),
                      highlightColor: Colors.white.withValues(alpha: .10),
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: 1.3,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: context.reduceMotion
                                    ? Duration.zero
                                    : HabiterMotion.quick.normal,
                                width: selected ? 56 : 48,
                                height: selected ? 56 : 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      Color.lerp(
                                        _iconColor(destination),
                                        Colors.white,
                                        .34,
                                      )!,
                                      _iconColor(destination),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .58),
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: _iconColor(
                                        destination,
                                      ).withValues(alpha: .28),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _icon(destination),
                                  color: const Color(0xff171717),
                                  size: selected ? 27 : 23,
                                ),
                              ),
                              const SizedBox(height: 11),
                              Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: dark
                                      ? const Color(0xfff7f1e8)
                                      : const Color(0xff171717),
                                  fontSize: selected ? 13.5 : 12.5,
                                  height: 1.05,
                                  letterSpacing: -.18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              AnimatedContainer(
                                duration: context.reduceMotion
                                    ? Duration.zero
                                    : HabiterMotion.quick.normal,
                                curve: HabiterMotion.quick.curve,
                                width: selected ? 34 : 18,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: _iconColor(
                                    destination,
                                  ).withValues(alpha: selected ? .88 : .40),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onCardTap(int index) {
    _focusNode.requestFocus();
    if (index == _settledIndex && _deltaFor(index).abs() < .5) {
      widget.onOpen(habitHubDestinations[index]);
      return;
    }
    final delta = _deltaFor(index);
    _selectRaw((_position.value + delta).round());
  }

  void _snapToNearest() => _selectRaw(_position.value.round());

  void _settleAfterDrag(DragEndDetails details) {
    final velocity = (-(details.primaryVelocity ?? 0) / _dragExtent).clamp(
      -8.0,
      8.0,
    );
    final nearest = _position.value.round();
    final projected = (_position.value + velocity * .16).round();
    final target = projected.clamp(nearest - 2, nearest + 2);
    _settleWithSpring(target, velocity);
  }

  void _settleWithSpring(int target, double velocity) {
    if (context.reduceMotion) {
      _position.value = target.toDouble();
      _commit(target);
      return;
    }
    unawaited(
      _position
          .animateWith(
            SpringSimulation(
              const SpringDescription(mass: 1, stiffness: 430, damping: 34),
              _position.value,
              target.toDouble(),
              velocity,
              tolerance: const Tolerance(distance: .001, velocity: .015),
            ),
          )
          .then((_) => _commit(target)),
    );
  }

  void _selectRaw(int target) {
    final reduced = context.reduceMotion;
    if (reduced) {
      _position.value = target.toDouble();
      _commit(target);
      return;
    }
    unawaited(
      _position
          .animateTo(
            target.toDouble(),
            duration: HabiterMotion.standard.normal,
            curve: HabiterMotion.standard.curve,
          )
          .then((_) => _commit(target)),
    );
  }

  void _commit(int rawIndex) {
    if (!mounted) return;
    final index = _normalize(rawIndex);
    if (index == _settledIndex) return;
    _settledIndex = index;
    widget.onSelectionChanged?.call(habitHubDestinations[index]);
    final haptics = Provider.of<HapticGateway?>(context, listen: false);
    if (haptics != null) unawaited(haptics.selection());
    setState(() {});
  }

  double _deltaFor(int itemIndex) {
    final turn = ((_position.value - itemIndex) / _count).round();
    return itemIndex + turn * _count - _position.value;
  }

  int _normalize(int index) => ((index % _count) + _count) % _count;
}

class _WheelBed extends StatelessWidget {
  const _WheelBed({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) => Positioned(
    left: -90,
    right: -90,
    top: 78,
    height: 260,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(240)),
        gradient: RadialGradient(
          center: const Alignment(0, -.15),
          radius: .86,
          colors: dark
              ? const <Color>[Color(0xff50393d), Color(0xff281e23)]
              : const <Color>[Color(0xffe8b5aa), Color(0xffd7a6ad)],
        ),
      ),
    ),
  );
}

class _OpenButton extends StatelessWidget {
  const _OpenButton({
    required this.top,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final double top;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    left: 0,
    right: 0,
    child: Center(
      child: Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            key: const Key('hub-wheel-open'),
            color: const Color(0xff151515),
            shape: const CircleBorder(
              side: BorderSide(color: Color(0xff343434), width: 2),
            ),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: .28),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox.square(
                dimension: 62,
                child: Icon(icon, color: Colors.white, size: 27),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _label(BuildContext context, HabitHubDestination destination) =>
    switch (destination) {
      HabitHubDestination.today => context.l10n.today,
      HabitHubDestination.createHabit => context.l10n.createHabit,
      HabitHubDestination.analytics => context.l10n.analytics,
      HabitHubDestination.appLock => context.l10n.appLock,
      HabitHubDestination.rhythm => context.l10n.habitSchedule,
      HabitHubDestination.updates => context.l10n.updateCenterTitle,
      HabitHubDestination.settings => context.l10n.settings,
    };

IconData _icon(HabitHubDestination destination) => switch (destination) {
  HabitHubDestination.today => Icons.today_rounded,
  HabitHubDestination.createHabit => Icons.add_rounded,
  HabitHubDestination.analytics => Icons.insights_rounded,
  HabitHubDestination.appLock => Icons.lock_outline_rounded,
  HabitHubDestination.rhythm => Icons.calendar_month_rounded,
  HabitHubDestination.updates => Icons.system_update_alt_rounded,
  HabitHubDestination.settings => Icons.tune_rounded,
};

Color _iconColor(HabitHubDestination destination) => switch (destination) {
  HabitHubDestination.today => const Color(0xff9dded9),
  HabitHubDestination.createHabit => const Color(0xffffcf91),
  HabitHubDestination.analytics => const Color(0xffd7acd0),
  HabitHubDestination.appLock => const Color(0xffaebfe5),
  HabitHubDestination.rhythm => const Color(0xffb9dca8),
  HabitHubDestination.updates => const Color(0xffffb7a8),
  HabitHubDestination.settings => const Color(0xffddd0b8),
};

Color _paperColor(BuildContext context, HabitHubDestination destination) {
  if (_isDark(context)) {
    return Color.lerp(const Color(0xff312d2c), _iconColor(destination), .08)!;
  }
  return Color.lerp(const Color(0xfffffbf3), _iconColor(destination), .08)!;
}

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
