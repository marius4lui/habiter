import 'package:flutter/material.dart';

import '../../../../models/habit.dart';
import '../../application/app_block_onboarding_controller.dart';
import '../../domain/app_block_rule.dart';
import 'app_block_onboarding_page.dart';

final class AppHabitBindingPage extends StatefulWidget {
  const AppHabitBindingPage({
    required this.controller,
    required this.habits,
    super.key,
  });

  final AppBlockOnboardingController controller;
  final List<Habit> habits;

  @override
  State<AppHabitBindingPage> createState() => _AppHabitBindingPageState();
}

final class _AppHabitBindingPageState extends State<AppHabitBindingPage> {
  bool _general = true;
  final Set<String> _habitIds = <String>{};

  List<Habit> get _activeHabits =>
      widget.habits.where((habit) => habit.isActive).toList(growable: false);

  @override
  Widget build(BuildContext context) => AppBlockOnboardingPage(
    title: 'What should these apps protect?',
    subtitle: 'Apply one rule quickly, then adjust individual apps if needed.',
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RadioListTile<bool>(
          key: const Key('app-block-binding-general'),
          value: true,
          groupValue: _general,
          onChanged: (_) => setState(() => _general = true),
          title: const Text('My focus in general'),
          subtitle: const Text(
            'All habits relevant today can gate these apps.',
          ),
        ),
        RadioListTile<bool>(
          key: const Key('app-block-binding-specific'),
          value: false,
          groupValue: _general,
          onChanged: (_) => setState(() => _general = false),
          title: const Text('Specific habits'),
        ),
        if (!_general)
          Wrap(
            spacing: 8,
            children: _activeHabits
                .map(
                  (habit) => FilterChip(
                    key: Key('app-block-habit-${habit.id}'),
                    label: Text(habit.name),
                    selected: _habitIds.contains(habit.id),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _habitIds.add(habit.id);
                      } else {
                        _habitIds.remove(habit.id);
                      }
                    }),
                  ),
                )
                .toList(growable: false),
          ),
        const SizedBox(height: 24),
        Text('Your rules', style: Theme.of(context).textTheme.titleLarge),
        for (final rule in widget.controller.state.rules)
          ListTile(
            key: Key('app-block-rule-${rule.packageName}'),
            title: Text(rule.appName),
            subtitle: Text(_requirementLabel(rule.requirement)),
            trailing: PopupMenuButton<AppBlockRequirement>(
              tooltip: 'Change binding',
              onSelected: (requirement) =>
                  widget.controller.overrideRule(rule.packageName, requirement),
              itemBuilder: (context) => <PopupMenuEntry<AppBlockRequirement>>[
                const PopupMenuItem<AppBlockRequirement>(
                  value: GeneralRequirement(),
                  child: Text('General'),
                ),
                if (_habitIds.isNotEmpty)
                  PopupMenuItem<AppBlockRequirement>(
                    value: HabitRequirement(_habitIds),
                    child: const Text('Selected habits'),
                  ),
              ],
            ),
          ),
      ],
    ),
    primary: FilledButton(
      key: const Key('app-block-confirm-bindings'),
      onPressed: !_general && _habitIds.isEmpty
          ? null
          : () async {
              final requirement = _general
                  ? const GeneralRequirement()
                  : HabitRequirement(_habitIds);
              await widget.controller.bindAll(requirement);
              await widget.controller.showBehaviorEducation();
            },
      child: const Text('Continue'),
    ),
  );

  String _requirementLabel(AppBlockRequirement requirement) =>
      switch (requirement) {
        GeneralRequirement() => 'General focus',
        HabitRequirement(:final habitIds) =>
          _activeHabits
              .where((habit) => habitIds.contains(habit.id))
              .map((habit) => habit.name)
              .join(' + '),
      };
}
