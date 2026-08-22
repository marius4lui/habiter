import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/haptics.dart';
import '../core/design_system/motion.dart';
import '../core/design_system/tokens.dart';
import '../features/habits/presentation/editor/habit_editor_draft.dart';
import '../features/habits/presentation/templates/habit_template.dart';
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
  final _searchController = TextEditingController();
  late String _category;
  late HabitFrequency _frequency;
  int _targetCount = 1;
  late String _color;
  late String _icon;
  final Set<int> _selectedWeekdays = <int>{};
  bool _notificationEnabled = false;
  String? _notificationTime;
  HabitTemplateGroup _templateGroup = HabitTemplateGroup.popular;
  HabitTemplate? _selectedTemplate;
  bool _identityReady = false;
  int _step = 0;
  bool _saving = false;
  bool _success = false;

  bool get _editing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    if (habit == null) {
      _category = HabitCategories.health;
      _frequency = HabitFrequency.daily;
      _color = '#467B68';
      _icon = '💧';
      return;
    }
    _identityReady = true;
    _nameController.text = habit.name;
    _descriptionController.text = habit.description ?? '';
    _category = habit.category;
    _frequency = habit.frequency;
    _targetCount = habit.targetCount;
    _color = habit.color;
    _icon = habit.icon;
    _selectedWeekdays.addAll(habit.customDays ?? const <int>[]);
    _notificationEnabled = habit.notificationEnabled;
    _notificationTime = habit.notificationTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return FractionallySizedBox(
      heightFactor: .96,
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
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(HabiterRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editing ? l10n.editHabit : l10n.newHabit,
                            style: theme.textTheme.headlineSmall,
                          ),
                          if (!_editing && !_success) ...[
                            const SizedBox(height: 2),
                            Text(
                              l10n.stepOf(_step + 1, 3),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_editing)
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
                                const SizedBox(width: HabiterSpace.sm2),
                                Text(l10n.deleteHabit),
                              ],
                            ),
                          ),
                        ],
                      ),
                    IconButton(
                      tooltip: l10n.cancel,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              if (!_editing && !_success) _ProgressRail(step: _step),
              Expanded(
                child: AnimatedSwitcher(
                  duration: HabiterMotion.standard.duration(
                    reduced: context.reduceMotion,
                  ),
                  switchInCurve: HabiterMotion.standard.curve,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.035, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _success
                      ? const _CreationSuccess(key: ValueKey('success'))
                      : _editing
                      ? KeyedSubtree(
                          key: const ValueKey('edit'),
                          child: _buildEdit(),
                        )
                      : KeyedSubtree(
                          key: ValueKey('create-$_step-$_identityReady'),
                          child: switch (_step) {
                            0 =>
                              _identityReady
                                  ? _buildIdentity()
                                  : _buildTemplatePicker(),
                            1 => _buildSchedule(),
                            _ => _buildSupportAndReview(),
                          },
                        ),
                ),
              ),
              if (!_success && (_editing || _identityReady)) _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatePicker() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final templates = HabitTemplate.catalog
        .where((template) {
          final inGroup =
              query.isNotEmpty || template.groups.contains(_templateGroup);
          final searchable = <String>[
            template.localizedName(l10n),
            localizedHabitCategory(l10n, template.category),
            template.id.replaceAll('_', ' '),
          ].join(' ').toLowerCase();
          return inGroup && (query.isEmpty || searchable.contains(query));
        })
        .toList(growable: false);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(l10n.creationQuestion, style: theme.textTheme.headlineMedium),
        const SizedBox(height: HabiterSpace.lg),
        TextField(
          key: const Key('template-search'),
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: l10n.searchTemplates,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: HabiterSpace.md),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: HabitTemplateGroup.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: HabiterSpace.sm),
            itemBuilder: (_, index) {
              final group = HabitTemplateGroup.values[index];
              return ChoiceChip(
                key: ValueKey('template-group-${group.name}'),
                label: Text(localizedTemplateGroup(l10n, group)),
                selected: query.isEmpty && group == _templateGroup,
                onSelected: (_) {
                  _searchController.clear();
                  setState(() => _templateGroup = group);
                },
              );
            },
          ),
        ),
        const SizedBox(height: HabiterSpace.sm2),
        OutlinedButton.icon(
          key: const Key('custom-habit-action'),
          onPressed: () => _startCustom(_searchController.text),
          icon: const Icon(Icons.edit_outlined),
          label: Text(
            query.isEmpty
                ? l10n.customHabitAction
                : l10n.customHabitFromSearch(_searchController.text.trim()),
          ),
        ),
        const SizedBox(height: HabiterSpace.lg),
        Text(l10n.starterTemplates, style: theme.textTheme.titleLarge),
        const SizedBox(height: HabiterSpace.sm2),
        LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final columns = largeText
                ? 1
                : constraints.maxWidth >= 520
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: HabiterSpace.sm2,
                mainAxisSpacing: HabiterSpace.sm2,
                mainAxisExtent: largeText ? 184 : 132,
              ),
              itemBuilder: (_, index) {
                final template = templates[index];
                return _TemplateTile(
                  key: ValueKey('template-${template.id}'),
                  template: template,
                  onTap: () => _selectTemplate(template),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildIdentity() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.habitIdentityQuestion,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: HabiterSpace.xs),
            Text(
              l10n.habitIdentityHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: HabiterSpace.lg),
            _HabitPreview(
              icon: _icon,
              name: _nameController.text.trim().isEmpty
                  ? l10n.namePlaceholder
                  : _nameController.text.trim(),
              meta:
                  '${localizedHabitCategory(l10n, _category)} · ${_schedulePreview()}',
              color: _color,
            ),
            const SizedBox(height: HabiterSpace.lg),
            TextFormField(
              key: const Key('habit-name-field'),
              controller: _nameController,
              autofocus: _selectedTemplate == null,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: l10n.namePlaceholder,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.nameRequired
                  : null,
            ),
            const SizedBox(height: HabiterSpace.lg),
            _IdentityControls(
              category: _category,
              icon: _icon,
              color: _color,
              onCategory: (value) => setState(() {
                _category = value;
                final icons = _iconsFor(value);
                if (!icons.contains(_icon)) _icon = icons.first;
              }),
              onIcon: (value) {
                _selectionHaptic();
                setState(() => _icon = value);
              },
              onColor: (value) {
                _selectionHaptic();
                setState(() => _color = value);
              },
            ),
            if (_selectedTemplate != null) ...[
              const SizedBox(height: HabiterSpace.md),
              TextButton.icon(
                onPressed: _chooseAnotherTemplate,
                icon: const Icon(Icons.grid_view_rounded),
                label: Text(l10n.chooseAnotherTemplate),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSchedule() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    children: _scheduleChildren(showHeading: true),
  );

  List<Widget> _scheduleChildren({required bool showHeading}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monday = DateTime.utc(2024, 1, 1);
    final firstDayIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstIsoWeekday = firstDayIndex == 0 ? 7 : firstDayIndex;
    return [
      if (showHeading) ...[
        Text(l10n.rhythmQuestion, style: theme.textTheme.headlineMedium),
        const SizedBox(height: HabiterSpace.xs),
        Text(
          l10n.rhythmHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: HabiterSpace.lg),
      ],
      _FrequencyOption(
        key: const Key('frequency-daily'),
        icon: Icons.today_rounded,
        title: l10n.daily,
        body: l10n.dailyOptionBody,
        selected: _frequency == HabitFrequency.daily,
        onTap: () => _setFrequency(HabitFrequency.daily),
      ),
      const SizedBox(height: HabiterSpace.sm),
      _FrequencyOption(
        key: const Key('frequency-weekly'),
        icon: Icons.repeat_rounded,
        title: l10n.weekly,
        body: l10n.weeklyOptionBody,
        selected: _frequency == HabitFrequency.weekly,
        onTap: () => _setFrequency(HabitFrequency.weekly),
      ),
      const SizedBox(height: HabiterSpace.sm),
      _FrequencyOption(
        key: const Key('frequency-custom'),
        icon: Icons.date_range_rounded,
        title: l10n.custom,
        body: l10n.customOptionBody,
        selected: _frequency == HabitFrequency.custom,
        onTap: () => _setFrequency(HabitFrequency.custom),
      ),
      if (_frequency == HabitFrequency.weekly) ...[
        const SizedBox(height: HabiterSpace.lg),
        Text(l10n.targetPerWeek, style: theme.textTheme.titleMedium),
        const SizedBox(height: HabiterSpace.sm),
        Wrap(
          spacing: HabiterSpace.sm,
          runSpacing: HabiterSpace.sm,
          children: [
            for (var target = 1; target <= 7; target++)
              ChoiceChip(
                key: ValueKey('target-$target'),
                label: Text('$target'),
                selected: _targetCount == target,
                onSelected: (_) {
                  _selectionHaptic();
                  setState(() => _targetCount = target);
                },
              ),
          ],
        ),
        const SizedBox(height: HabiterSpace.sm),
        Text(
          l10n.perWeek(_targetCount),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      if (_frequency == HabitFrequency.custom) ...[
        const SizedBox(height: HabiterSpace.lg),
        Text(l10n.selectDays, style: theme.textTheme.titleMedium),
        const SizedBox(height: HabiterSpace.sm),
        Wrap(
          spacing: HabiterSpace.sm,
          runSpacing: HabiterSpace.sm,
          children: List.generate(7, (index) {
            final day = ((firstIsoWeekday - 1 + index) % 7) + 1;
            final selected = _selectedWeekdays.contains(day);
            return Semantics(
              selected: selected,
              button: true,
              child: FilterChip(
                key: ValueKey('weekday-$day'),
                label: Text(
                  DateFormat.E(
                    locale,
                  ).format(monday.add(Duration(days: day - 1))),
                ),
                selected: selected,
                onSelected: (_) {
                  _selectionHaptic();
                  setState(() {
                    selected
                        ? _selectedWeekdays.remove(day)
                        : _selectedWeekdays.add(day);
                  });
                },
              ),
            );
          }),
        ),
      ],
      const SizedBox(height: HabiterSpace.lg),
      _HabitPreview(
        icon: _icon,
        name: _nameController.text.trim(),
        meta:
            '${localizedHabitCategory(l10n, _category)} · ${_schedulePreview()}',
        color: _color,
        compact: true,
      ),
    ];
  }

  Widget _buildSupportAndReview() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(l10n.reminderQuestion, style: theme.textTheme.headlineMedium),
        const SizedBox(height: HabiterSpace.xs),
        Text(
          l10n.reminderSupportBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: HabiterSpace.lg),
        ..._reminderChildren(),
        const SizedBox(height: HabiterSpace.sm),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: HabiterSpace.sm),
          leading: const Icon(Icons.notes_rounded),
          title: Text(l10n.detailsOptional),
          children: [_descriptionField()],
        ),
        const SizedBox(height: HabiterSpace.lg),
        Text(l10n.reviewHabit, style: theme.textTheme.titleLarge),
        const SizedBox(height: HabiterSpace.sm2),
        _HabitPreview(
          icon: _icon,
          name: _nameController.text.trim(),
          meta: _reviewMeta(),
          color: _color,
        ),
      ],
    );
  }

  Widget _buildEdit() => Form(
    key: _formKey,
    child: ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _HabitPreview(
          icon: _icon,
          name: _nameController.text.trim(),
          meta: _reviewMeta(),
          color: _color,
        ),
        const SizedBox(height: HabiterSpace.lg),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(labelText: context.l10n.name),
          validator: (value) => value == null || value.trim().isEmpty
              ? context.l10n.nameRequired
              : null,
        ),
        const SizedBox(height: HabiterSpace.md),
        _descriptionField(),
        const SizedBox(height: HabiterSpace.lg),
        _IdentityControls(
          category: _category,
          icon: _icon,
          color: _color,
          onCategory: (value) => setState(() => _category = value),
          onIcon: (value) => setState(() => _icon = value),
          onColor: (value) => setState(() => _color = value),
        ),
        const SizedBox(height: HabiterSpace.xl),
        Text(
          context.l10n.habitSchedule,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: HabiterSpace.md),
        ..._scheduleChildren(showHeading: false),
        const SizedBox(height: HabiterSpace.xl),
        Text(
          context.l10n.habitReminder,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: HabiterSpace.sm2),
        ..._reminderChildren(),
      ],
    ),
  );

  List<Widget> _reminderChildren() => [
    HabiterSurface(
      padding: EdgeInsets.zero,
      child: SwitchListTile.adaptive(
        key: const Key('reminder-switch'),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HabiterSpace.md,
          vertical: HabiterSpace.xs,
        ),
        title: Text(context.l10n.habitReminderToggle),
        subtitle: Text(
          _notificationEnabled
              ? context.l10n.dailyReminderAt(_notificationTime ?? '20:00')
              : context.l10n.dailyReminderOff,
        ),
        value: _notificationEnabled,
        onChanged: (value) {
          _selectionHaptic();
          setState(() {
            _notificationEnabled = value;
            if (value) _notificationTime ??= '20:00';
          });
        },
      ),
    ),
    if (_notificationEnabled) ...[
      const SizedBox(height: HabiterSpace.sm2),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickReminderTime,
          icon: const Icon(Icons.schedule_outlined),
          label: Text(_notificationTime ?? context.l10n.reminderTime),
        ),
      ),
    ],
  ];

  Widget _descriptionField() => TextFormField(
    controller: _descriptionController,
    maxLines: 3,
    textInputAction: TextInputAction.done,
    onTapOutside: (_) => FocusScope.of(context).unfocus(),
    decoration: InputDecoration(
      labelText: '${context.l10n.description} · ${context.l10n.optional}',
      hintText: context.l10n.descriptionPlaceholder,
    ),
  );

  Widget _buildActions() {
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              if (!_editing && _step > 0) ...[
                IconButton.outlined(
                  tooltip: l10n.backLabel,
                  onPressed: _saving ? null : () => setState(() => _step--),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: HabiterSpace.sm2),
              ],
              Expanded(
                child: FilledButton.icon(
                  key: Key(
                    _editing ? 'update-habit-action' : 'create-habit-action',
                  ),
                  onPressed: _saving
                      ? null
                      : _editing
                      ? _save
                      : _step == 2
                      ? _save
                      : _continue,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _editing || _step == 2
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    _editing
                        ? l10n.updateHabit
                        : _step == 2
                        ? l10n.createHabit
                        : l10n.continueLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTemplate(HabitTemplate template) {
    _selectionHaptic();
    setState(() {
      _selectedTemplate = template;
      _nameController.text = template.localizedName(context.l10n);
      _category = template.category;
      _icon = template.icon;
      _color = template.color;
      _frequency = template.frequency;
      _targetCount = template.targetCount;
      _selectedWeekdays
        ..clear()
        ..addAll(template.customDays);
      _identityReady = true;
    });
  }

  void _startCustom(String initialName) {
    _selectionHaptic();
    setState(() {
      _selectedTemplate = null;
      _nameController.text = initialName.trim();
      _identityReady = true;
    });
  }

  void _chooseAnotherTemplate() {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedTemplate = null;
      _identityReady = false;
      _searchController.clear();
    });
  }

  void _setFrequency(HabitFrequency value) {
    _selectionHaptic();
    setState(() {
      _frequency = value;
      if (value == HabitFrequency.daily) _targetCount = 1;
      if (value == HabitFrequency.weekly) {
        _targetCount = _targetCount.clamp(1, 7);
      }
    });
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
    if (_editing && !(_formKey.currentState?.validate() ?? false)) return;
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
    final errors = draft.validate();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errors.containsKey('customDays')
                ? context.l10n.scheduleRequired
                : context.l10n.reminderTimeRequired,
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<HabitProvider>();
    final current = widget.habit;
    if (current == null) {
      await provider.addHabit(
        name: draft.name.trim(),
        description: draft.description?.trim().isEmpty == true
            ? null
            : draft.description?.trim(),
        category: draft.category,
        frequency: draft.frequency,
        targetCount: draft.targetCount,
        color: draft.color,
        icon: draft.icon,
        customDays: draft.frequency == HabitFrequency.custom
            ? draft.customDays
            : null,
        notificationEnabled: draft.notificationEnabled,
        notificationTime: draft.notificationTime,
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
    if (!mounted) return;
    await _successHaptic();
    if (!mounted) return;
    if (_editing) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _success = true;
    });
    await Future<void>.delayed(
      HabiterMotion.emphasized.duration(reduced: context.reduceMotion),
    );
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

  List<String> _iconsFor(String category) {
    final suggestions = getHabitIconSuggestions();
    if (category == HabitCategories.home) {
      return const <String>['🧹', '🏠', '🧺', '🌱', '🧽'];
    }
    return suggestions[category] ?? const <String>['✓', '⭐', '🎯'];
  }

  String _schedulePreview() => switch (_frequency) {
    HabitFrequency.daily => context.l10n.daily,
    HabitFrequency.weekly => context.l10n.perWeek(_targetCount),
    HabitFrequency.custom => context.l10n.onDays(
      _targetCount,
      _selectedWeekdays.length,
    ),
  };

  String _reviewMeta() {
    final parts = <String>[
      _schedulePreview(),
      localizedHabitCategory(context.l10n, _category),
    ];
    if (_notificationEnabled && _notificationTime != null) {
      parts.add(context.l10n.dailyReminderAt(_notificationTime!));
    }
    return parts.join(' · ');
  }

  Future<void> _selectionHaptic() async {
    try {
      await context.read<HapticGateway>().selection();
    } on ProviderNotFoundException {
      await const SystemHapticGateway().selection();
    }
  }

  Future<void> _successHaptic() async {
    try {
      await context.read<HapticGateway>().success();
    } on ProviderNotFoundException {
      await const SystemHapticGateway().success();
    }
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Padding(
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
              color: index <= step
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(HabiterRadius.pill),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({super.key, required this.template, required this.onTap});

  final HabitTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = template.color.asHabiterColor;
    return Semantics(
      button: true,
      label:
          '${template.localizedName(context.l10n)}, ${localizedHabitCategory(context.l10n, template.category)}',
      child: Material(
        color: Color.alphaBlend(
          accent.withValues(
            alpha: theme.brightness == Brightness.dark ? .13 : .08,
          ),
          theme.colorScheme.surfaceContainerLow,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.card),
          side: BorderSide(color: accent.withValues(alpha: .2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HabiterSpace.sm2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(HabiterRadius.control),
                  ),
                  child: Text(
                    template.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const Spacer(),
                Text(
                  template.localizedName(context.l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  template.frequency == HabitFrequency.weekly
                      ? context.l10n.perWeek(template.targetCount)
                      : context.l10n.daily,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityControls extends StatelessWidget {
  const _IdentityControls({
    required this.category,
    required this.icon,
    required this.color,
    required this.onCategory,
    required this.onIcon,
    required this.onColor,
  });

  final String category;
  final String icon;
  final String color;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onIcon;
  final ValueChanged<String> onColor;

  @override
  Widget build(BuildContext context) {
    final suggestions = getHabitIconSuggestions();
    final icons = category == HabitCategories.home
        ? const <String>['🧹', '🏠', '🧺', '🌱', '🧽']
        : suggestions[category] ?? const <String>['✓', '⭐', '🎯'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.category,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: HabiterSpace.sm),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: HabitCategories.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: HabiterSpace.sm),
            itemBuilder: (_, index) {
              final value = HabitCategories.values[index];
              return ChoiceChip(
                label: Text(localizedHabitCategory(context.l10n, value)),
                selected: value == category,
                onSelected: (_) => onCategory(value),
              );
            },
          ),
        ),
        const SizedBox(height: HabiterSpace.lg),
        Text(context.l10n.icon, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HabiterSpace.sm),
        Wrap(
          spacing: HabiterSpace.sm,
          runSpacing: HabiterSpace.sm,
          children: [
            for (final value in icons)
              Semantics(
                selected: value == icon,
                button: true,
                child: ChoiceChip(
                  label: Text(value, style: const TextStyle(fontSize: 20)),
                  selected: value == icon,
                  onSelected: (_) => onIcon(value),
                ),
              ),
          ],
        ),
        const SizedBox(height: HabiterSpace.lg),
        Text(
          context.l10n.color,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: HabiterSpace.sm),
        Wrap(
          spacing: HabiterSpace.sm2,
          runSpacing: HabiterSpace.sm2,
          children: [
            for (final value in const <String>[
              '#467B68',
              '#3E7CB1',
              '#7B61A8',
              '#C45B42',
              '#A66E3F',
              '#397A77',
              '#92712E',
            ])
              Semantics(
                selected: value == color,
                button: true,
                label: value,
                child: InkWell(
                  borderRadius: BorderRadius.circular(HabiterRadius.pill),
                  onTap: () => onColor(value),
                  child: AnimatedContainer(
                    duration: HabiterMotion.quick.duration(
                      reduced: context.reduceMotion,
                    ),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: value.asHabiterColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: value == color
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: value == color
                        ? Icon(
                            Icons.check_rounded,
                            color:
                                ThemeData.estimateBrightnessForColor(
                                      value.asHabiterColor,
                                    ) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  const _FrequencyOption({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabiterRadius.card),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: .45)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HabiterSpace.md),
            child: Row(
              children: [
                Icon(icon, color: selected ? theme.colorScheme.primary : null),
                const SizedBox(width: HabiterSpace.sm2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: HabiterMotion.quick.duration(
                    reduced: context.reduceMotion,
                  ),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    key: ValueKey(selected),
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitPreview extends StatelessWidget {
  const _HabitPreview({
    required this.icon,
    required this.name,
    required this.meta,
    required this.color,
    this.compact = false,
  });

  final String icon;
  final String name;
  final String meta;
  final String color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color.asHabiterColor;
    return AnimatedContainer(
      duration: HabiterMotion.standard.duration(reduced: context.reduceMotion),
      padding: EdgeInsets.all(compact ? HabiterSpace.md : HabiterSpace.lg),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(
            alpha: theme.brightness == Brightness.dark ? .14 : .09,
          ),
          theme.colorScheme.surfaceContainerLow,
        ),
        borderRadius: BorderRadius.circular(HabiterRadius.prominent),
        border: Border.all(color: accent.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: HabiterMotion.standard.duration(
              reduced: context.reduceMotion,
            ),
            width: compact ? 48 : 58,
            height: compact ? 48 : 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(HabiterRadius.control),
            ),
            child: Text(icon, style: TextStyle(fontSize: compact ? 24 : 28)),
          ),
          const SizedBox(width: HabiterSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: compact
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge,
                ),
                const SizedBox(height: HabiterSpace.xs),
                Text(
                  meta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreationSuccess extends StatelessWidget {
  const _CreationSuccess({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      liveRegion: true,
      label: context.l10n.ready,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: HabiterSpace.md),
          Text(
            context.l10n.ready,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    ),
  );
}
