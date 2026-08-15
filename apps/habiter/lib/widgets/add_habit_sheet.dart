import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/motion.dart';
import '../core/design_system/tokens.dart';
import '../features/habits/presentation/editor/habit_editor_draft.dart';
import '../l10n/l10n.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../utils/habit_utils.dart';

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key, this.habit});
  final Habit? habit;

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _category;
  late HabitFrequency _frequency;
  int _targetCount = 1;
  late String _color;
  late String _icon;
  final Set<int> _selectedWeekdays = {};
  bool _notificationEnabled = false;
  String? _notificationTime;
  int _step = 0;
  bool _saving = false;

  Map<String, List<String>> get _iconSuggestions => getHabitIconSuggestions();

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    if (habit == null) {
      _category = _iconSuggestions.keys.first;
      _frequency = HabitFrequency.daily;
      _color = getRandomColor();
      _icon = _iconSuggestions[_category]?.first ?? '✓';
      return;
    }
    _nameController.text = habit.name;
    _descriptionController.text = habit.description ?? '';
    _category = habit.category;
    _frequency = habit.frequency;
    _targetCount = habit.targetCount;
    _color = habit.color;
    _icon = habit.icon;
    _selectedWeekdays.addAll(habit.customDays ?? const []);
    _notificationEnabled = habit.notificationEnabled;
    _notificationTime = habit.notificationTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        color: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HabiterRadius.sheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: HabiterSpace.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(HabiterRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.habit == null
                                ? l10n.newHabit
                                : l10n.editHabit,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.stepOf(_step + 1, 3),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.habit != null)
                      PopupMenuButton<String>(
                        tooltip: l10n.advanced,
                        onSelected: (value) {
                          if (value == 'delete') _deleteHabit();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline),
                                const SizedBox(width: 12),
                                Text(l10n.deleteHabit),
                              ],
                            ),
                          ),
                        ],
                      ),
                    IconButton(
                      tooltip: l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        duration: HabiterMotion.quick.duration(
                          reduced: context.reduceMotion,
                        ),
                        height: 4,
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: index <= _step
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            HabiterRadius.pill,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${l10n.frequency}: ${_schedulePreview(context)}',
                    key: const ValueKey('schedule-preview'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: HabiterMotion.standard.duration(
                    reduced: context.reduceMotion,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      0 => _buildBasics(),
                      1 => _buildSchedule(),
                      _ => _buildReminder(),
                    },
                  ),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIntro(String title, String body, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: HabiterSpace.sm2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: HabiterSpace.xs),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasics() {
    final l10n = context.l10n;
    final categories = _iconSuggestions.keys.toList();
    final icons = _iconSuggestions[_category] ?? _iconSuggestions.values.first;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          _stepIntro(
            l10n.habitBasics,
            l10n.habitBasicsHint,
            Icons.spa_outlined,
          ),
          const SizedBox(height: HabiterSpace.lg),
          TextFormField(
            controller: _nameController,
            autofocus: widget.habit == null,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.name,
              hintText: l10n.namePlaceholder,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? l10n.nameRequired
                : null,
          ),
          const SizedBox(height: HabiterSpace.md),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '${l10n.description} · ${l10n.optional}',
              hintText: l10n.descriptionPlaceholder,
            ),
          ),
          const SizedBox(height: HabiterSpace.lg),
          Text(l10n.category, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: HabiterSpace.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                ChoiceChip(
                  label: Text(category),
                  selected: category == _category,
                  onSelected: (_) => setState(() {
                    _category = category;
                    _icon = _iconSuggestions[category]?.first ?? _icon;
                  }),
                ),
            ],
          ),
          const SizedBox(height: HabiterSpace.lg),
          Text(l10n.icon, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: HabiterSpace.sm),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: icons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final icon = icons[index];
                return Semantics(
                  button: true,
                  selected: icon == _icon,
                  child: ChoiceChip(
                    label: Text(icon, style: const TextStyle(fontSize: 22)),
                    selected: icon == _icon,
                    onSelected: (_) => setState(() => _icon = icon),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: HabiterSpace.lg),
          Text(l10n.color, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: HabiterSpace.sm),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in generateHabitColors())
                Semantics(
                  button: true,
                  selected: color == _color,
                  label: color,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(HabiterRadius.pill),
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.asHabiterColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == _color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule() {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monday = DateTime.utc(2024, 1, 1);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _stepIntro(
          l10n.habitSchedule,
          l10n.habitScheduleHint,
          Icons.calendar_today_outlined,
        ),
        const SizedBox(height: HabiterSpace.lg),
        SegmentedButton<HabitFrequency>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: HabitFrequency.daily, label: Text(l10n.daily)),
            ButtonSegment(
              value: HabitFrequency.weekly,
              label: Text(l10n.weekly),
            ),
            ButtonSegment(
              value: HabitFrequency.custom,
              label: Text(l10n.custom),
            ),
          ],
          selected: {_frequency},
          onSelectionChanged: (value) => setState(() {
            _frequency = value.single;
            if (_frequency == HabitFrequency.weekly && _targetCount > 7) {
              _targetCount = 7;
            }
          }),
        ),
        if (_frequency == HabitFrequency.custom) ...[
          const SizedBox(height: HabiterSpace.lg),
          Text(l10n.selectDays, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: HabiterSpace.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1;
              final selected = _selectedWeekdays.contains(day);
              return FilterChip(
                label: Text(
                  DateFormat.E(
                    locale,
                  ).format(monday.add(Duration(days: index))),
                ),
                selected: selected,
                onSelected: (_) => setState(() {
                  selected
                      ? _selectedWeekdays.remove(day)
                      : _selectedWeekdays.add(day);
                }),
              );
            }),
          ),
        ],
        const SizedBox(height: HabiterSpace.xl),
        HabiterSurface(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _frequency == HabitFrequency.weekly
                          ? l10n.targetPerWeek
                          : l10n.targetPerDay,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _frequency == HabitFrequency.weekly
                          ? context.l10n.perWeek(_targetCount)
                          : context.l10n.perDayTarget(_targetCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.decreaseTarget,
                onPressed: _targetCount > 1
                    ? () => setState(() => _targetCount--)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 34,
                child: Text('$_targetCount', textAlign: TextAlign.center),
              ),
              IconButton(
                tooltip: context.l10n.increaseTarget,
                onPressed:
                    _frequency == HabitFrequency.weekly && _targetCount >= 7
                    ? null
                    : () => setState(() => _targetCount++),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminder() {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _stepIntro(
          l10n.habitReminder,
          l10n.habitReminderHint,
          Icons.notifications_none_rounded,
        ),
        const SizedBox(height: HabiterSpace.lg),
        HabiterSurface(
          padding: EdgeInsets.zero,
          child: SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(l10n.dailyReminder),
            subtitle: Text(
              _notificationEnabled
                  ? l10n.dailyReminderAt(_notificationTime ?? '20:00')
                  : l10n.dailyReminderOff,
            ),
            value: _notificationEnabled,
            onChanged: (value) => setState(() {
              _notificationEnabled = value;
              if (value) _notificationTime ??= '20:00';
            }),
          ),
        ),
        if (_notificationEnabled) ...[
          const SizedBox(height: HabiterSpace.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickReminderTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(_notificationTime ?? l10n.reminderTime),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(
                  onPressed: _saving ? null : () => setState(() => _step--),
                  child: Text(l10n.backLabel),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : (_step == 2 ? _save : _continue),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _step == 2
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(_step == 2 ? l10n.saveHabit : l10n.continueLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() {
    if (_step == 0 && !(_formKey.currentState?.validate() ?? false)) return;
    if (_step == 1 &&
        _frequency == HabitFrequency.custom &&
        _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.scheduleRequired)));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step++);
  }

  Future<void> _save() async {
    final draft = HabitEditorDraft(
      name: _nameController.text,
      description: _descriptionController.text,
      category: _category,
      frequency: _frequency,
      targetCount: _targetCount,
      color: _color,
      icon: _icon,
      customDays: _selectedWeekdays,
      notificationEnabled: _notificationEnabled,
      notificationTime: _notificationTime,
    );
    if (draft.validate().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reminderTimeRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<HabitProvider>();
    final current = widget.habit;
    if (current == null) {
      await provider.addHabit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _category,
        frequency: _frequency,
        targetCount: _targetCount,
        color: _color,
        icon: _icon,
        customDays: _frequency == HabitFrequency.custom
            ? _selectedWeekdays.toList()
            : null,
        notificationEnabled: _notificationEnabled,
        notificationTime: _notificationTime,
      );
    } else {
      await provider.updateHabit(
        current.id,
        draft.toHabit(
          id: current.id,
          createdAt: current.createdAt,
          isActive: current.isActive,
          pauses: current.pauses,
          archivedAt: current.archivedAt,
          restoredAt: current.restoredAt,
          source: current.source,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteHabit() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteHabit),
        content: Text(l10n.deleteHabitConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<HabitProvider>().deleteHabit(widget.habit!.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickReminderTime() async {
    final parts = (_notificationTime ?? '20:00').split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 20,
        minute: int.tryParse(parts.last) ?? 0,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _notificationTime =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    });
  }

  String _schedulePreview(BuildContext context) => switch (_frequency) {
    HabitFrequency.daily => context.l10n.daily,
    HabitFrequency.weekly => context.l10n.perWeek(_targetCount),
    HabitFrequency.custom => context.l10n.onDays(
      _targetCount,
      _selectedWeekdays.length,
    ),
  };
}
