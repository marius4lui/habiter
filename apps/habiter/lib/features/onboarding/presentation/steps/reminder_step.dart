import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/haptics.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../../../providers/habit_provider.dart';
import '../../application/onboarding_controller.dart';
import '../onboarding_scaffold.dart';

class ReminderStep extends StatefulWidget {
  const ReminderStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<ReminderStep> createState() => _ReminderStepState();
}

class _ReminderStepState extends State<ReminderStep> {
  late bool _enabled;
  late TimeOfDay _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.state.habitDraft!;
    _enabled = draft.reminderEnabled;
    _time =
        _parseTime(draft.reminderTime) ?? const TimeOfDay(hour: 20, minute: 0);
  }

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
    step: 5,
    title: context.l10n.onboardingReminderTitle,
    subtitle: context.l10n.onboardingReminderBody,
    onBack: _saving ? null : widget.controller.back,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ReminderChoice(
          selected: !_enabled,
          icon: Icons.notifications_off_outlined,
          label: context.l10n.onboardingNoReminder,
          onTap: () => _setEnabled(false),
        ),
        _ReminderChoice(
          selected: _enabled,
          icon: Icons.notifications_active_outlined,
          label: context.l10n.onboardingAddReminder,
          onTap: () => _setEnabled(true),
        ),
        if (_enabled) ...<Widget>[
          const SizedBox(height: HabiterSpace.md),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule_rounded),
            label: Text(_time.format(context)),
          ),
        ],
        if (_saving) ...<Widget>[
          const SizedBox(height: HabiterSpace.lg),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: HabiterSpace.sm),
          Text(context.l10n.onboardingSaving, textAlign: TextAlign.center),
        ],
      ],
    ),
    primaryAction: FilledButton(
      onPressed: _saving ? null : _createHabit,
      child: Text(context.l10n.continueLabel),
    ),
  );

  Future<void> _setEnabled(bool value) async {
    await context.read<HapticGateway>().selection();
    setState(() => _enabled = value);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) setState(() => _time = selected);
  }

  Future<void> _createHabit() async {
    setState(() => _saving = true);
    final provider = context.read<HabitProvider>();
    final haptics = context.read<HapticGateway>();
    var reminderEnabled = _enabled;
    if (reminderEnabled) {
      reminderEnabled = await provider.requestHabitReminderPermission();
    }
    if (!mounted) return;
    final draft = widget.controller.state.habitDraft!.copyWith(
      reminderEnabled: reminderEnabled,
      reminderTime: reminderEnabled ? _serializedTime : null,
      clearReminderTime: !reminderEnabled,
    );
    await widget.controller.configureReminder(draft);
    final id = await widget.controller.reserveFirstHabitId();
    await provider.addHabit(
      id: id,
      name: draft.name,
      category: draft.category,
      frequency: draft.frequency,
      targetCount: draft.targetCount,
      color: draft.color,
      icon: draft.icon,
      customDays: draft.customDays,
      notificationEnabled: draft.reminderEnabled,
      notificationTime: draft.reminderTime,
    );
    if (draft.reminderEnabled) await provider.scheduleHabitReminder(id);
    await haptics.success();
    await widget.controller.markHabitReady();
  }

  String get _serializedTime =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _parseTime(String? value) {
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class _ReminderChoice extends StatelessWidget {
  const _ReminderChoice({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
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
                Icon(icon),
                const SizedBox(width: HabiterSpace.md),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
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
