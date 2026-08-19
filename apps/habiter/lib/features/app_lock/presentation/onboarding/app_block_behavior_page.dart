import 'package:flutter/material.dart';

import '../../../../models/habit.dart';
import '../../../habits/domain/habit_schedule.dart';
import '../../application/app_block_onboarding_controller.dart';
import '../../domain/app_block_rule.dart';
import 'app_block_onboarding_page.dart';

final class AppBlockBehaviorPage extends StatelessWidget {
  const AppBlockBehaviorPage({
    required this.controller,
    required this.habits,
    super.key,
  });

  final AppBlockOnboardingController controller;
  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final hasGeneral = controller.state.rules.any(
      (rule) => rule.requirement is GeneralRequirement,
    );
    final relevantIds = controller.state.rules
        .expand(
          (rule) => switch (rule.requirement) {
            GeneralRequirement() => const <String>[],
            HabitRequirement(:final habitIds) => habitIds,
          },
        )
        .toSet();
    final relevant = hasGeneral
        ? habits.where((habit) => habit.isActive)
        : habits.where((habit) => relevantIds.contains(habit.id));
    return AppBlockOnboardingPage(
      title: 'How blocking follows your rhythm',
      subtitle:
          'Habiter evaluates the same schedules your habits already use. It does not invent extra due days.',
      body: Column(
        children: relevant
            .map(
              (habit) => Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: Text(habit.name),
                  subtitle: Text(_scheduleLabel(habit)),
                  trailing: const Icon(Icons.lock_clock_rounded),
                ),
              ),
            )
            .toList(growable: false),
      ),
      primary: FilledButton(
        key: const Key('app-block-behavior-continue'),
        onPressed: controller.showOverlayEducation,
        child: const Text('I understand'),
      ),
    );
  }

  String _scheduleLabel(Habit habit) {
    final schedule = LegacyHabitScheduleMapper.fromHabit(habit);
    return switch (schedule) {
      DailySchedule() => 'Daily · unlocks after today’s completion',
      WeekdaySchedule(:final weekdays) =>
        '${weekdays.map(_weekday).join(' · ')} · only scheduled days gate',
      TimesPerWeekSchedule(:final target) =>
        '$target× per week · one contribution unlocks today',
    };
  }

  String _weekday(int day) =>
      const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
}
