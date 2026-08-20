import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../components/onboarding_fact_chip.dart';
import '../components/week_target_demo.dart';
import '../models/schedule_education_model.dart';
import '../onboarding_scaffold.dart';

final class RhythmExplainerStep extends StatefulWidget {
  const RhythmExplainerStep({required this.controller, super.key});

  final OnboardingController controller;

  @override
  State<RhythmExplainerStep> createState() => _RhythmExplainerStepState();
}

class _RhythmExplainerStepState extends State<RhythmExplainerStep> {
  bool _interacted = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.controller.state.habitDraft!;
    final result = ScheduleEducationMapper.fromDraft(draft);
    if (result case ScheduleEducationInvalid()) {
      return OnboardingScaffold(
        step: OnboardingStep.rhythmExplainer,
        title: context.l10n.onboardingRhythmTitle,
        onBack: widget.controller.back,
        body: Text(context.l10n.onboardingRhythmInvalid),
      );
    }
    final model = (result as ScheduleEducationReady).model;
    return OnboardingScaffold(
      step: OnboardingStep.rhythmExplainer,
      title: _title(context, model),
      subtitle: _body(context, model),
      onBack: widget.controller.back,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WeekTargetDemo(
            model: model,
            weekLabel: context.l10n.onboardingRhythmWeekLabel,
            weekdayLabels: _weekdayLabels(context, short: true),
            progressLabelBuilder: context.l10n.onboardingRhythmProgress,
            progressSemanticsBuilder:
                context.l10n.onboardingRhythmProgressSemantics,
            weekdaySemanticsBuilder: (weekday, selected, enabled) {
              final state = selected
                  ? context.l10n.onboardingRhythmDaySelected
                  : enabled
                  ? context.l10n.onboardingRhythmDayNotSelected
                  : context.l10n.onboardingRhythmDayUnavailable;
              return '${_weekdayLabels(context, short: false)[weekday]}, $state';
            },
            haptics: context.read<HapticGateway>(),
            onProgressChanged: (_) {
              if (!_interacted) setState(() => _interacted = true);
            },
          ),
          const SizedBox(height: HabiterSpace.md),
          Text(
            context.l10n.onboardingRhythmTryPrompt,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HabiterSpace.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: HabiterSpace.sm,
            runSpacing: HabiterSpace.sm,
            children: [
              OnboardingFactChip(
                icon: Icons.looks_one_rounded,
                label: context.l10n.onboardingRhythmFactDifferentDays,
              ),
              OnboardingFactChip(
                icon: Icons.calendar_view_week_rounded,
                label: context.l10n.onboardingRhythmFactMondayReset,
              ),
              if (model.kind == ScheduleEducationKind.flexibleWeekly)
                OnboardingFactChip(
                  icon: Icons.done_all_rounded,
                  label: context.l10n.onboardingRhythmFactConsecutive,
                  emphasized: true,
                ),
            ],
          ),
        ],
      ),
      primaryAction: FilledButton(
        onPressed: _interacted
            ? widget.controller.confirmRhythmUnderstanding
            : null,
        child: Text(context.l10n.onboardingWidgetUnderstood),
      ),
    );
  }

  String _title(BuildContext context, ScheduleEducationModel model) =>
      switch (model.kind) {
        ScheduleEducationKind.daily =>
          context.l10n.onboardingRhythmExplainerDailyTitle,
        ScheduleEducationKind.flexibleWeekly =>
          context.l10n.onboardingRhythmExplainerFlexibleTitle(
            model.weeklyTarget,
          ),
        ScheduleEducationKind.fixedWeekdays =>
          context.l10n.onboardingRhythmExplainerFixedTitle,
      };

  String _body(BuildContext context, ScheduleEducationModel model) =>
      switch (model.kind) {
        ScheduleEducationKind.daily =>
          context.l10n.onboardingRhythmExplainerDailyBody,
        ScheduleEducationKind.flexibleWeekly =>
          context.l10n.onboardingRhythmExplainerFlexibleBody,
        ScheduleEducationKind.fixedWeekdays =>
          context.l10n.onboardingRhythmExplainerFixedBody,
      };

  Map<int, String> _weekdayLabels(BuildContext context, {required bool short}) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return <int, String>{
      for (var day = 1; day <= 7; day++)
        day: (short ? DateFormat.E(locale) : DateFormat.EEEE(locale)).format(
          DateTime.utc(2026, 8, 17 + day - 1),
        ),
    };
  }
}
