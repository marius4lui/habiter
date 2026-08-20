import 'package:flutter/material.dart';

import '../../../../core/design_system/motion.dart';
import '../../../../core/design_system/tokens.dart';

typedef ReminderProgressLabelBuilder =
    String Function(int completed, int target);
typedef ReminderTimeLabelBuilder = String Function(TimeOfDay time);

final class ReminderTimelineDemo extends StatefulWidget {
  const ReminderTimelineDemo({
    required this.habitName,
    required this.habitIcon,
    required this.scheduleLabel,
    required this.initialCompleted,
    required this.target,
    required this.initialReminderTime,
    required this.progressLabelBuilder,
    required this.progressSemanticsBuilder,
    required this.timeLabelBuilder,
    required this.reminderQuestion,
    required this.doneLabel,
    required this.laterLabel,
    required this.resetLabel,
    required this.doneExplanation,
    required this.laterExplanation,
    this.onInteracted,
    super.key,
  }) : assert(initialCompleted >= 0),
       assert(target > 0),
       assert(initialCompleted <= target);

  final String habitName;
  final String habitIcon;
  final String scheduleLabel;
  final int initialCompleted;
  final int target;
  final TimeOfDay initialReminderTime;
  final ReminderProgressLabelBuilder progressLabelBuilder;
  final ReminderProgressLabelBuilder progressSemanticsBuilder;
  final ReminderTimeLabelBuilder timeLabelBuilder;
  final String reminderQuestion;
  final String doneLabel;
  final String laterLabel;
  final String resetLabel;
  final String doneExplanation;
  final String laterExplanation;
  final VoidCallback? onInteracted;

  @override
  State<ReminderTimelineDemo> createState() => _ReminderTimelineDemoState();
}

enum _DemoOutcome { idle, done, later }

class _ReminderTimelineDemoState extends State<ReminderTimelineDemo> {
  late int _completed;
  late TimeOfDay _reminderTime;
  _DemoOutcome _outcome = _DemoOutcome.idle;
  bool _interactionReported = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.initialCompleted;
    _reminderTime = widget.initialReminderTime;
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = context.reduceMotion;
    final colors = Theme.of(context).colorScheme;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.habitIcon, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: HabiterSpace.sm2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.habitName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          widget.scheduleLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    key: const ValueKey<String>('reminder-demo-progress'),
                    container: true,
                    label: widget.progressSemanticsBuilder(
                      _completed,
                      widget.target,
                    ),
                    excludeSemantics: true,
                    child: AnimatedDefaultTextStyle(
                      duration: HabiterMotion.quick.duration(
                        reduced: reducedMotion,
                      ),
                      curve: HabiterMotion.quick.curve,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(),
                      child: Text(
                        widget.progressLabelBuilder(_completed, widget.target),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HabiterSpace.lg),
              _timeline(context),
              const SizedBox(height: HabiterSpace.lg),
              AnimatedSwitcher(
                duration: HabiterMotion.standard.duration(
                  reduced: reducedMotion,
                ),
                child: _outcome == _DemoOutcome.done
                    ? _feedbackCard(
                        key: const ValueKey<String>('reminder-demo-done'),
                        context: context,
                        icon: Icons.check_circle_rounded,
                        text: widget.doneExplanation,
                      )
                    : _reminderCard(context),
              ),
              if (_outcome != _DemoOutcome.idle) ...[
                const SizedBox(height: HabiterSpace.sm),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    key: const ValueKey<String>('reminder-demo-reset'),
                    onPressed: _reset,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(widget.resetLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeline(BuildContext context) {
    final minutes = _reminderTime.hour * 60 + _reminderTime.minute;
    final fraction = ((minutes - 8 * 60) / (14 * 60)).clamp(0.0, 1.0);
    return Semantics(
      key: const ValueKey<String>('reminder-demo-time'),
      container: true,
      label: widget.timeLabelBuilder(_reminderTime),
      excludeSemantics: true,
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('08'),
              Text('12'),
              Text('16'),
              Text('20'),
              Text('22'),
            ],
          ),
          const SizedBox(height: HabiterSpace.xs),
          LinearProgressIndicator(value: fraction, minHeight: 8),
          const SizedBox(height: HabiterSpace.sm),
          Text(
            widget.timeLabelBuilder(_reminderTime),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(BuildContext context) => Card(
    key: const ValueKey<String>('reminder-demo-card'),
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(HabiterSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.habitName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: HabiterSpace.xs),
          Text(widget.reminderQuestion),
          if (_outcome == _DemoOutcome.later) ...[
            const SizedBox(height: HabiterSpace.sm),
            Text(
              widget.laterExplanation,
              key: const ValueKey<String>('reminder-demo-later'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: HabiterSpace.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: HabiterSpace.sm,
            runSpacing: HabiterSpace.sm,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey<String>('reminder-demo-done-action'),
                onPressed: _done,
                icon: const Icon(Icons.done_rounded),
                label: Text(widget.doneLabel),
              ),
              OutlinedButton.icon(
                key: const ValueKey<String>('reminder-demo-later-action'),
                onPressed: _later,
                icon: const Icon(Icons.snooze_rounded),
                label: Text(widget.laterLabel),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _feedbackCard({
    required Key key,
    required BuildContext context,
    required IconData icon,
    required String text,
  }) => Semantics(
    key: key,
    container: true,
    liveRegion: true,
    label: text,
    excludeSemantics: true,
    child: Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(HabiterSpace.md),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: HabiterSpace.sm2),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    ),
  );

  void _done() {
    setState(() {
      _completed = (_completed + 1).clamp(0, widget.target);
      _outcome = _DemoOutcome.done;
    });
    _reportInteraction();
  }

  void _later() {
    final minutes =
        (_reminderTime.hour * 60 + _reminderTime.minute + 30) % (24 * 60);
    setState(() {
      _reminderTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
      _outcome = _DemoOutcome.later;
    });
    _reportInteraction();
  }

  void _reset() => setState(() {
    _completed = widget.initialCompleted;
    _reminderTime = widget.initialReminderTime;
    _outcome = _DemoOutcome.idle;
  });

  void _reportInteraction() {
    if (_interactionReported) return;
    _interactionReported = true;
    widget.onInteracted?.call();
  }
}
