import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../../models/habit.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../onboarding_scaffold.dart';

class RhythmStep extends StatefulWidget {
  const RhythmStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<RhythmStep> createState() => _RhythmStepState();
}

class _RhythmStepState extends State<RhythmStep> {
  late HabitFrequency _frequency;
  late int _target;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.state.habitDraft!;
    _frequency = draft.frequency;
    _target = draft.targetCount.clamp(1, 7);
    _days = draft.customDays.toSet();
  }

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    step: OnboardingStep.rhythm,
    title: context.l10n.onboardingRhythmTitle,
    onBack: widget.controller.back,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _RhythmChoice(
          selected: _frequency == HabitFrequency.daily,
          icon: Icons.today_rounded,
          title: context.l10n.onboardingEveryDay,
          body: context.l10n.onboardingEveryDayBody,
          onTap: () => _select(HabitFrequency.daily),
        ),
        _RhythmChoice(
          selected: _frequency == HabitFrequency.weekly,
          icon: Icons.repeat_rounded,
          title: context.l10n.onboardingSeveralTimes,
          body: context.l10n.onboardingSeveralTimesBody,
          onTap: () => _select(HabitFrequency.weekly),
        ),
        _RhythmChoice(
          selected: _frequency == HabitFrequency.custom,
          icon: Icons.calendar_view_week_rounded,
          title: context.l10n.onboardingSpecificDays,
          body: context.l10n.onboardingSpecificDaysBody,
          onTap: () => _select(HabitFrequency.custom),
        ),
        if (_frequency == HabitFrequency.weekly) ...<Widget>[
          const SizedBox(height: HabiterSpace.md),
          Text(
            context.l10n.onboardingTimesPerWeek(_target),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: HabiterSpace.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: HabiterSpace.xs,
            children: <Widget>[
              for (var value = 1; value <= 7; value++)
                ChoiceChip(
                  label: Text('$value'),
                  selected: _target == value,
                  onSelected: (_) => _setTarget(value),
                ),
            ],
          ),
        ],
        if (_frequency == HabitFrequency.custom) ...<Widget>[
          const SizedBox(height: HabiterSpace.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: HabiterSpace.xs,
            runSpacing: HabiterSpace.xs,
            children: <Widget>[
              for (var day = 1; day <= 7; day++)
                FilterChip(
                  label: Text(_weekday(context, day)),
                  selected: _days.contains(day),
                  onSelected: (_) => _toggleDay(day),
                ),
            ],
          ),
        ],
      ],
    ),
    primaryAction: FilledButton(
      onPressed: _frequency == HabitFrequency.custom && _days.isEmpty
          ? null
          : _continue,
      child: Text(context.l10n.continueLabel),
    ),
  );

  Future<void> _select(HabitFrequency value) async {
    await context.read<HapticGateway>().selection();
    setState(() => _frequency = value);
  }

  Future<void> _setTarget(int value) async {
    await context.read<HapticGateway>().selection();
    setState(() => _target = value);
  }

  Future<void> _toggleDay(int value) async {
    await context.read<HapticGateway>().selection();
    setState(() {
      if (!_days.add(value)) _days.remove(value);
    });
  }

  Future<void> _continue() {
    final draft = widget.controller.state.habitDraft!.copyWith(
      frequency: _frequency,
      targetCount: _frequency == HabitFrequency.weekly ? _target : 1,
      customDays: _frequency == HabitFrequency.custom ? _days : const <int>[],
    );
    return widget.controller.configureRhythm(draft);
  }

  String _weekday(BuildContext context, int day) {
    final date = DateTime.utc(2026, 8, 17 + day - 1);
    return DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }
}

class _RhythmChoice extends StatelessWidget {
  const _RhythmChoice({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HabiterSpace.sm),
    child: Semantics(
      selected: selected,
      button: true,
      child: Card(
        color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HabiterSpace.md),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 30),
                const SizedBox(width: HabiterSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(body),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
