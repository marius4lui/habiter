import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
                    onHorizontalDragEnd: (_) => _snapToNearest(),
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
                              28,
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
    final scale = (1 - delta.abs() * .12).clamp(.72, 1.0);
    final left = width / 2 + math.sin(angle) * radius - cardWidth / 2;
    final top = 8 + (1 - math.cos(angle)) * radius * .58;
    final selected = index == _nearestIndex;
    final label = _label(context, destination);

    return Positioned(
      left: left,
      top: top,
      width: cardWidth,
      height: cardHeight,
      child: Transform.rotate(
        angle: delta * .16,
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Semantics(
            button: true,
            selected: selected,
            label: context.l10n.habitHubWheelPosition(label, index + 1, _count),
            onTap: () => _onCardTap(index),
            child: ExcludeSemantics(
              child: Material(
                key: Key('hub-wheel-card-${destination.name}'),
                color: _paperColor(context, destination),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: _isDark(context)
                        ? Colors.white.withValues(alpha: .12)
                        : Colors.white.withValues(alpha: .72),
                  ),
                ),
                elevation: selected ? 2 : 0,
                shadowColor: Colors.black.withValues(alpha: .14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _onCardTap(index),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: _iconColor(destination),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(
                              dimension: selected ? 52 : 46,
                              child: Icon(
                                _icon(destination),
                                color: const Color(0xff171717),
                                size: selected ? 26 : 23,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDark(context)
                                  ? const Color(0xfff7f1e8)
                                  : const Color(0xff171717),
                              fontSize: 13,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
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
