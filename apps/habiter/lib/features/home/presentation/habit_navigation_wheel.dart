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
                        _WheelBed(
                          dark: _isDark(context),
                          accent: _iconColor(selected),
                        ),
                        ..._cards(context, constraints.maxWidth),
                        _OpenButton(
                          top:
                              (constraints.maxWidth * .43).clamp(138.0, 172.0) *
                                  .94 +
                              6,
                          label: context.l10n.habitHubOpenDestination(
                            _label(
                              context,
                              habitHubDestinations[_settledIndex],
                            ),
                          ),
                          icon: _icon(habitHubDestinations[_settledIndex]),
                          accent: _iconColor(
                            habitHubDestinations[_settledIndex],
                          ),
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
    final scale = .79 + easedFocus * .21;
    final left = width / 2 + math.sin(angle) * radius - cardWidth / 2;
    final top = -16 + (1 - math.cos(angle)) * radius * .62;
    final selected = index == _nearestIndex;
    final label = _label(context, destination);
    final paper = _paperColor(context, destination);
    final dark = _isDark(context);
    final compactCard = cardWidth < 150;

    return Positioned(
      left: left,
      top: top,
      width: cardWidth,
      height: cardHeight,
      child: Opacity(
        opacity: .54 + depth * .46,
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
                      colors: _cardGradient(
                        paper: paper,
                        accent: _iconColor(destination),
                        selected: selected,
                        dark: dark,
                      ),
                    ),
                    border: Border.all(
                      color: selected
                          ? _iconColor(
                              destination,
                            ).withValues(alpha: dark ? .82 : .96)
                          : dark
                          ? Colors.white.withValues(alpha: .12)
                          : Colors.white.withValues(alpha: .76),
                      width: selected ? 2 : 1,
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
                      child: Stack(
                        children: [
                          Positioned(
                            top: compactCard ? 8 : 12,
                            right: compactCard ? 8 : 12,
                            child: AnimatedScale(
                              scale: selected ? 1 : 0,
                              duration: context.reduceMotion
                                  ? Duration.zero
                                  : HabiterMotion.quick.normal,
                              curve: Curves.easeOutBack,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xff171717),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .76),
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: .22,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const SizedBox.square(
                                  dimension: 24,
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.3,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                14,
                                compactCard ? 9 : 13,
                                14,
                                compactCard ? 8 : 11,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  AnimatedContainer(
                                    duration: context.reduceMotion
                                        ? Duration.zero
                                        : HabiterMotion.quick.normal,
                                    width: selected
                                        ? (compactCard ? 50 : 58)
                                        : (compactCard ? 44 : 48),
                                    height: selected
                                        ? (compactCard ? 50 : 58)
                                        : (compactCard ? 44 : 48),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: <Color>[
                                          Color.lerp(
                                            _iconColor(destination),
                                            Colors.white,
                                            .42,
                                          )!,
                                          _iconColor(destination),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: selected ? .88 : .56,
                                        ),
                                        width: selected ? 1.6 : 1,
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: _iconColor(destination)
                                              .withValues(
                                                alpha: selected ? .40 : .24,
                                              ),
                                          blurRadius: selected ? 20 : 12,
                                          offset: const Offset(0, 7),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _icon(destination),
                                      color: const Color(0xff171717),
                                      size: selected
                                          ? (compactCard ? 25 : 29)
                                          : (compactCard ? 21 : 23),
                                    ),
                                  ),
                                  SizedBox(height: compactCard ? 7 : 10),
                                  Text(
                                    label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: dark
                                          ? const Color(0xfff7f1e8)
                                          : const Color(0xff171717),
                                      fontSize: selected
                                          ? (compactCard ? 13.5 : 14.5)
                                          : (compactCard ? 12 : 12.5),
                                      height: 1.02,
                                      letterSpacing: selected ? -.28 : -.12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Spacer(),
                                  AnimatedContainer(
                                    duration: context.reduceMotion
                                        ? Duration.zero
                                        : HabiterMotion.quick.normal,
                                    curve: HabiterMotion.quick.curve,
                                    width: selected ? 46 : 20,
                                    height: selected ? 5 : 3,
                                    decoration: BoxDecoration(
                                      color: _iconColor(
                                        destination,
                                      ).withValues(alpha: selected ? 1 : .54),
                                      borderRadius: BorderRadius.circular(99),
                                      boxShadow: selected
                                          ? <BoxShadow>[
                                              BoxShadow(
                                                color: _iconColor(
                                                  destination,
                                                ).withValues(alpha: .38),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
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
  const _WheelBed({required this.dark, required this.accent});

  final bool dark;
  final Color accent;

  @override
  Widget build(BuildContext context) => Positioned(
    left: -90,
    right: -90,
    top: 78,
    height: 260,
    child: AnimatedContainer(
      duration: context.reduceMotion
          ? Duration.zero
          : HabiterMotion.standard.normal,
      curve: HabiterMotion.standard.curve,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(240)),
        gradient: RadialGradient(
          center: const Alignment(0, -.15),
          radius: .86,
          colors: dark
              ? <Color>[
                  Color.lerp(const Color(0xff50393d), accent, .25)!,
                  const Color(0xff281e23),
                ]
              : <Color>[
                  Color.lerp(const Color(0xfff1c8bd), accent, .34)!,
                  Color.lerp(const Color(0xffd7a6ad), accent, .12)!,
                ],
        ),
        border: Border(
          top: BorderSide(
            color: Color.lerp(
              Colors.white,
              accent,
              .18,
            )!.withValues(alpha: dark ? .18 : .54),
          ),
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
    required this.accent,
    required this.onPressed,
  });

  final double top;
  final String label;
  final IconData icon;
  final Color accent;
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
          child: AnimatedContainer(
            key: const Key('hub-wheel-open'),
            duration: context.reduceMotion
                ? Duration.zero
                : HabiterMotion.standard.normal,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xff303030), Color(0xff101010)],
              ),
              border: Border.all(
                color: Color.lerp(const Color(0xff4a4a4a), accent, .56)!,
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: .34),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: .28),
                  blurRadius: 22,
                  spreadRadius: -5,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: accent.withValues(alpha: .24),
                onTap: onPressed,
                child: SizedBox.square(
                  dimension: 62,
                  child: Icon(
                    icon,
                    color: Color.lerp(Colors.white, accent, .16),
                    size: 27,
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
  HabitHubDestination.today => const Color(0xff65cec3),
  HabitHubDestination.createHabit => const Color(0xffffbd62),
  HabitHubDestination.analytics => const Color(0xffc889c5),
  HabitHubDestination.appLock => const Color(0xff8fa9e8),
  HabitHubDestination.rhythm => const Color(0xff8dca78),
  HabitHubDestination.updates => const Color(0xffff917c),
  HabitHubDestination.settings => const Color(0xffb9a586),
};

Color _paperColor(BuildContext context, HabitHubDestination destination) {
  if (_isDark(context)) {
    return Color.lerp(const Color(0xff312d2c), _iconColor(destination), .18)!;
  }
  return Color.lerp(const Color(0xfffffbf3), _iconColor(destination), .20)!;
}

List<Color> _cardGradient({
  required Color paper,
  required Color accent,
  required bool selected,
  required bool dark,
}) {
  if (dark) {
    return <Color>[
      Color.lerp(paper, accent, selected ? .30 : .10)!,
      Color.lerp(paper, Colors.black, selected ? .08 : .16)!,
    ];
  }
  return <Color>[
    Color.lerp(Colors.white, accent, selected ? .40 : .16)!,
    Color.lerp(paper, accent, selected ? .20 : .06)!,
  ];
}

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
