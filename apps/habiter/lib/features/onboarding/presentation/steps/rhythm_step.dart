import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../../models/habit.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../components/habit_illustration.dart';
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
        HabitIllustration(
          kind: HabitIllustrationKind.garden,
          step: OnboardingStep.rhythm,
          semanticLabel: context.l10n.onboardingRhythmTitle,
          height: 128,
        ),
        const SizedBox(height: HabiterSpace.md),
        _RhythmChoice(
          code: '01',
          selected: _frequency == HabitFrequency.daily,
          title: context.l10n.onboardingEveryDay,
          body: context.l10n.onboardingEveryDayBody,
          onTap: () => _select(HabitFrequency.daily),
        ),
        _RhythmChoice(
          code: '02',
          selected: _frequency == HabitFrequency.weekly,
          title: context.l10n.onboardingSeveralTimes,
          body: context.l10n.onboardingSeveralTimesBody,
          onTap: () => _select(HabitFrequency.weekly),
        ),
        _RhythmChoice(
          code: '03',
          selected: _frequency == HabitFrequency.custom,
          title: context.l10n.onboardingSpecificDays,
          body: context.l10n.onboardingSpecificDaysBody,
          onTap: () => _select(HabitFrequency.custom),
        ),
        if (_frequency == HabitFrequency.weekly) ...<Widget>[
          const SizedBox(height: HabiterSpace.sm),
          _ChoicePanel(
            label: context.l10n.onboardingTimesPerWeek(_target),
            child: Wrap(
              spacing: HabiterSpace.sm,
              runSpacing: HabiterSpace.sm,
              children: <Widget>[
                for (var value = 1; value <= 7; value++)
                  _CountChoice(
                    value: value,
                    selected: _target == value,
                    onTap: () => _setTarget(value),
                  ),
              ],
            ),
          ),
        ],
        if (_frequency == HabitFrequency.custom) ...<Widget>[
          const SizedBox(height: HabiterSpace.sm),
          _ChoicePanel(
            label: context.l10n.onboardingSpecificDaysBody,
            child: Wrap(
              spacing: HabiterSpace.sm,
              runSpacing: HabiterSpace.sm,
              children: <Widget>[
                for (var day = 1; day <= 7; day++)
                  _DayChoice(
                    day: day,
                    label: _weekday(context, day),
                    selected: _days.contains(day),
                    onTap: () => _toggleDay(day),
                  ),
              ],
            ),
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
    if (!mounted) return;
    setState(() => _frequency = value);
  }

  Future<void> _setTarget(int value) async {
    await context.read<HapticGateway>().selection();
    if (!mounted) return;
    setState(() => _target = value);
  }

  Future<void> _toggleDay(int value) async {
    await context.read<HapticGateway>().selection();
    if (!mounted) return;
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
    required this.code,
    required this.selected,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: HabiterSpace.sm),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? scheme.primary : scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HabiterRadius.card),
            side: BorderSide(
              color: scheme.primary.withValues(alpha: selected ? 1 : 0.16),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.all(HabiterSpace.md),
                child: Row(
                  children: <Widget>[
                    Text(
                      code,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(width: HabiterSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: HabiterSpace.xxs),
                          Text(
                            body,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: foreground.withValues(alpha: 0.76),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: HabiterSpace.sm),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: foreground, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: selected
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: foreground,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoicePanel extends StatelessWidget {
  const _ChoicePanel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(HabiterSpace.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(HabiterRadius.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: HabiterSpace.sm2),
        child,
      ],
    ),
  );
}

class _CountChoice extends StatelessWidget {
  const _CountChoice({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _EditorialToggle(
    key: ValueKey<String>('rhythm-target-$value'),
    label: '$value',
    selected: selected,
    onTap: onTap,
  );
}

class _DayChoice extends StatelessWidget {
  const _DayChoice({
    required this.day,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _EditorialToggle(
    key: ValueKey<String>('rhythm-day-$day'),
    label: label,
    selected: selected,
    onTap: onTap,
  );
}

class _EditorialToggle extends StatelessWidget {
  const _EditorialToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: HabiterSpace.sm2),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
