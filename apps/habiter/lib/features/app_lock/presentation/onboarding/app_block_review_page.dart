import 'package:flutter/material.dart';

import '../../../../models/habit.dart';
import '../../application/app_block_onboarding_controller.dart';
import '../../domain/app_block_rule.dart';
import 'app_block_onboarding_page.dart';

final class AppBlockReviewPage extends StatelessWidget {
  const AppBlockReviewPage({
    required this.controller,
    required this.habits,
    super.key,
  });

  final AppBlockOnboardingController controller;
  final List<Habit> habits;

  @override
  Widget build(BuildContext context) => AppBlockOnboardingPage(
    title: 'Ready to protect your focus',
    subtitle:
        'Review your per-app rules. You can change or disable them later.',
    body: Column(
      children: controller.state.rules
          .map(
            (rule) => ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(rule.appName),
              subtitle: Text(_label(rule.requirement)),
            ),
          )
          .toList(growable: false),
    ),
    primary: FilledButton(
      key: const Key('app-block-activate'),
      onPressed: controller.loading ? null : controller.complete,
      child: Text(controller.loading ? 'Activating…' : 'Activate App Block'),
    ),
  );

  String _label(AppBlockRequirement requirement) => switch (requirement) {
    GeneralRequirement() => 'General focus',
    HabitRequirement(:final habitIds) =>
      habits
          .where((habit) => habitIds.contains(habit.id))
          .map((habit) => habit.name)
          .join(' + '),
  };
}
