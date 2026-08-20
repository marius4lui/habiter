import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../application/onboarding_controller.dart';
import '../../application/onboarding_state.dart';
import '../components/reminder_timeline_demo.dart';
import '../models/schedule_education_model.dart';
import '../onboarding_scaffold.dart';

final class ReminderEducationStep extends StatefulWidget {
  const ReminderEducationStep({required this.controller, super.key});

  final OnboardingController controller;

  @override
  State<ReminderEducationStep> createState() => _ReminderEducationStepState();
}

class _ReminderEducationStepState extends State<ReminderEducationStep> {
  bool _interacted = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.controller.state.habitDraft!;
    final result = ScheduleEducationMapper.fromDraft(draft);
    if (result case ScheduleEducationInvalid()) {
      return OnboardingScaffold(
        step: OnboardingStep.reminderModel,
        title: context.l10n.onboardingReminderEducationTitle,
        onBack: widget.controller.back,
        body: Text(context.l10n.onboardingRhythmInvalid),
      );
    }
    final model = (result as ScheduleEducationReady).model;
    return OnboardingScaffold(
      step: OnboardingStep.reminderModel,
      title: context.l10n.onboardingReminderEducationTitle,
      subtitle: context.l10n.onboardingReminderEducationBody,
      onBack: widget.controller.back,
      body: ReminderTimelineDemo(
        key: const ValueKey<String>('onboarding-reminder-timeline-story'),
        habitName: draft.name,
        habitIcon: draft.icon,
        scheduleLabel: _scheduleLabel(context, model),
        initialCompleted: model.weeklyTarget > 1 ? 1 : 0,
        target: model.weeklyTarget,
        initialReminderTime: const TimeOfDay(hour: 16, minute: 15),
        progressLabelBuilder: context.l10n.onboardingRhythmProgress,
        progressSemanticsBuilder:
            context.l10n.onboardingReminderProgressSemantics,
        timeLabelBuilder: (time) =>
            MaterialLocalizations.of(context).formatTimeOfDay(time),
        reminderQuestion: context.l10n.onboardingReminderQuestion,
        doneLabel: context.l10n.done,
        laterLabel: context.l10n.onboardingWidgetLater,
        resetLabel: context.l10n.onboardingReminderResetDemo,
        doneExplanation: context.l10n.onboardingReminderDoneExplanation,
        laterExplanation: context.l10n.onboardingReminderLaterExplanation,
        onInteracted: () {
          if (!_interacted) setState(() => _interacted = true);
        },
      ),
      primaryAction: FilledButton(
        onPressed: _interacted ? widget.controller.confirmReminderModel : null,
        child: Text(context.l10n.onboardingWidgetUnderstood),
      ),
    );
  }

  String _scheduleLabel(BuildContext context, ScheduleEducationModel model) =>
      switch (model.kind) {
        ScheduleEducationKind.daily => context.l10n.onboardingEveryDay,
        ScheduleEducationKind.flexibleWeekly =>
          context.l10n.onboardingTimesPerWeek(model.weeklyTarget),
        ScheduleEducationKind.fixedWeekdays =>
          context.l10n.onboardingSpecificDays,
      };
}
