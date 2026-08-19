import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/motion.dart';
import '../../../../core/design_system/tokens.dart';
import '../models/schedule_education_model.dart';

typedef WeekProgressLabelBuilder = String Function(int completed, int target);
typedef WeekdaySemanticsBuilder =
    String Function(int weekday, bool selected, bool enabled);

final class WeekTargetDemo extends StatefulWidget {
  const WeekTargetDemo({
    required this.model,
    required this.weekLabel,
    required this.weekdayLabels,
    required this.progressLabelBuilder,
    required this.progressSemanticsBuilder,
    required this.weekdaySemanticsBuilder,
    this.onProgressChanged,
    this.haptics,
    super.key,
  }) : assert(weekdayLabels.length == 7);

  final ScheduleEducationModel model;
  final String weekLabel;
  final Map<int, String> weekdayLabels;
  final WeekProgressLabelBuilder progressLabelBuilder;
  final WeekProgressLabelBuilder progressSemanticsBuilder;
  final WeekdaySemanticsBuilder weekdaySemanticsBuilder;
  final ValueChanged<int>? onProgressChanged;
  final HapticGateway? haptics;

  @override
  State<WeekTargetDemo> createState() => _WeekTargetDemoState();
}

class _WeekTargetDemoState extends State<WeekTargetDemo> {
  final Set<int> _selectedWeekdays = <int>{};

  int get _completed =>
      _selectedWeekdays.length.clamp(0, widget.model.weeklyTarget);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = context.reduceMotion;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(HabiterRadius.card),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(HabiterSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.weekLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Semantics(
                    key: const ValueKey<String>('week-demo-progress'),
                    container: true,
                    label: widget.progressSemanticsBuilder(
                      _completed,
                      widget.model.weeklyTarget,
                    ),
                    excludeSemantics: true,
                    child: AnimatedDefaultTextStyle(
                      duration: HabiterMotion.quick.duration(
                        reduced: reducedMotion,
                      ),
                      curve: HabiterMotion.quick.curve,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _completed >= widget.model.weeklyTarget
                                ? colors.primary
                                : colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(),
                      child: Text(
                        widget.progressLabelBuilder(
                          _completed,
                          widget.model.weeklyTarget,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HabiterSpace.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: HabiterSpace.sm,
                runSpacing: HabiterSpace.sm,
                children: [
                  for (final weekday in widget.model.weekdaysInDisplayOrder)
                    _dayButton(context, weekday, reducedMotion),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayButton(BuildContext context, int weekday, bool reducedMotion) {
    final eligible = widget.model.eligibleWeekdays.contains(weekday);
    final selected = _selectedWeekdays.contains(weekday);
    final targetReached = _completed >= widget.model.weeklyTarget;
    final enabled = eligible && (selected || !targetReached);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      key: ValueKey<String>('week-demo-day-$weekday'),
      button: true,
      selected: selected,
      enabled: enabled,
      label: widget.weekdaySemanticsBuilder(weekday, selected, enabled),
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (enabled) _toggle(weekday);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _toggle(weekday) : null,
          child: AnimatedContainer(
            duration: HabiterMotion.quick.duration(reduced: reducedMotion),
            curve: HabiterMotion.quick.curve,
            constraints: const BoxConstraints.tightFor(
              width: HabiterState.minimumTarget,
              height: HabiterState.minimumTarget,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest.withValues(
                      alpha: enabled ? 1 : HabiterState.disabledOpacity,
                    ),
              borderRadius: BorderRadius.circular(HabiterRadius.control),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Text(
              widget.weekdayLabels[weekday]!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? colors.onPrimaryContainer
                    : colors.onSurface.withValues(
                        alpha: enabled ? 1 : HabiterState.disabledOpacity,
                      ),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(int weekday) {
    setState(() {
      if (!_selectedWeekdays.remove(weekday)) {
        _selectedWeekdays.add(weekday);
      }
    });
    widget.haptics?.selection();
    widget.onProgressChanged?.call(_completed);
  }
}
