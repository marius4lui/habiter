import 'dart:collection';

import '../../../habits/domain/habit_schedule.dart';
import '../../../../models/habit.dart';
import '../../application/onboarding_state.dart';

enum ScheduleEducationKind { daily, flexibleWeekly, fixedWeekdays }

enum ScheduleEducationIssue {
  invalidWeeklyTarget,
  missingFixedWeekdays,
  invalidFixedWeekday,
}

sealed class ScheduleEducationResult {
  const ScheduleEducationResult();
}

final class ScheduleEducationReady extends ScheduleEducationResult {
  const ScheduleEducationReady(this.model);

  final ScheduleEducationModel model;
}

final class ScheduleEducationInvalid extends ScheduleEducationResult {
  const ScheduleEducationInvalid(this.issue);

  final ScheduleEducationIssue issue;
}

/// Immutable, copy-free rendering data derived from the canonical schedule.
///
/// This model contains no localized copy and deliberately owns no counting
/// rules. Interactive demos may change their local [progressSeed], but product
/// progress continues to be evaluated by `HabitScheduleProgress`.
final class ScheduleEducationModel {
  ScheduleEducationModel._({
    required this.kind,
    required this.weeklyTarget,
    required Iterable<int> eligibleWeekdays,
    required Iterable<int> weekdaysInDisplayOrder,
    required this.progressSeed,
  }) : eligibleWeekdays = UnmodifiableSetView<int>(
         Set<int>.of(eligibleWeekdays),
       ),
       weekdaysInDisplayOrder = UnmodifiableListView<int>(
         List<int>.of(weekdaysInDisplayOrder),
       );

  static const mondayFirstWeekdays = <int>[1, 2, 3, 4, 5, 6, 7];

  final ScheduleEducationKind kind;
  final int weeklyTarget;
  final Set<int> eligibleWeekdays;
  final List<int> weekdaysInDisplayOrder;
  final int progressSeed;

  bool get weekStartsOnMonday => weekdaysInDisplayOrder.first == 1;

  static ScheduleEducationModel fromSchedule(HabitSchedule schedule) {
    final kind = switch (schedule) {
      DailySchedule() => ScheduleEducationKind.daily,
      TimesPerWeekSchedule() => ScheduleEducationKind.flexibleWeekly,
      WeekdaySchedule() => ScheduleEducationKind.fixedWeekdays,
    };
    final eligible = switch (schedule) {
      WeekdaySchedule(:final weekdays) => weekdays,
      _ => mondayFirstWeekdays,
    };
    return ScheduleEducationModel._(
      kind: kind,
      weeklyTarget: schedule.weeklyTarget,
      eligibleWeekdays: eligible,
      weekdaysInDisplayOrder: mondayFirstWeekdays,
      progressSeed: 0,
    );
  }
}

abstract final class ScheduleEducationMapper {
  static ScheduleEducationResult fromDraft(OnboardingHabitDraft draft) {
    final schedule = _scheduleFromDraft(draft);
    return switch (schedule) {
      _ScheduleReady(:final value) => ScheduleEducationReady(
        ScheduleEducationModel.fromSchedule(value),
      ),
      _ScheduleInvalid(:final issue) => ScheduleEducationInvalid(issue),
    };
  }

  static _ScheduleMapping _scheduleFromDraft(OnboardingHabitDraft draft) {
    switch (draft.frequency) {
      case HabitFrequency.daily:
        return const _ScheduleReady(DailySchedule());
      case HabitFrequency.weekly:
        try {
          return _ScheduleReady(TimesPerWeekSchedule(draft.targetCount));
        } on ArgumentError {
          return const _ScheduleInvalid(
            ScheduleEducationIssue.invalidWeeklyTarget,
          );
        }
      case HabitFrequency.custom:
        if (draft.customDays.isEmpty) {
          return const _ScheduleInvalid(
            ScheduleEducationIssue.missingFixedWeekdays,
          );
        }
        try {
          return _ScheduleReady(WeekdaySchedule(draft.customDays));
        } on ArgumentError {
          return const _ScheduleInvalid(
            ScheduleEducationIssue.invalidFixedWeekday,
          );
        }
    }
  }
}

sealed class _ScheduleMapping {
  const _ScheduleMapping();
}

final class _ScheduleReady extends _ScheduleMapping {
  const _ScheduleReady(this.value);

  final HabitSchedule value;
}

final class _ScheduleInvalid extends _ScheduleMapping {
  const _ScheduleInvalid(this.issue);

  final ScheduleEducationIssue issue;
}
