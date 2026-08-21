import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/components.dart';
import '../../../core/design_system/tokens.dart';
import '../../../l10n/l10n.dart';
import '../../../models/habit.dart';
import '../domain/widget_configuration.dart';
import '../domain/widget_configuration_gateway.dart';
import '../domain/widget_configuration_options.dart';
import 'widget_advanced_editor.dart';

class WidgetBasicEditor extends StatefulWidget {
  const WidgetBasicEditor({
    super.key,
    required this.instance,
    required this.habits,
    required this.gateway,
    this.configurationLaunch = false,
  });

  final WidgetInstance instance;
  final List<Habit> habits;
  final WidgetConfigurationGateway gateway;
  final bool configurationLaunch;

  @override
  State<WidgetBasicEditor> createState() => _WidgetBasicEditorState();
}

class _WidgetBasicEditorState extends State<WidgetBasicEditor> {
  late WidgetConfiguration _draft;
  late final TextEditingController _nameController;
  late List<String> _customOrder;
  bool _saving = false;

  List<Habit> get _availableHabits =>
      widget.habits.where((habit) => habit.isActive).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _draft = widget.instance.configuration;
    _nameController = TextEditingController(text: _draft.displayName);
    final availableIds = _availableHabits.map((habit) => habit.id).toList();
    _customOrder = <String>[
      ..._draft.customHabitOrder.where(availableIds.contains),
      ...availableIds.where((id) => !_draft.customHabitOrder.contains(id)),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(WidgetConfiguration value) => setState(() => _draft = value);

  void _setElementVisible(WidgetElement element, bool visible) {
    final hidden = Set<WidgetElement>.from(_draft.hiddenElements);
    visible ? hidden.remove(element) : hidden.add(element);
    _update(_draft.copyWith(hiddenElements: hidden));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final configuration = _draft.copyWith(
      displayName: name.isEmpty ? null : name,
      clearDisplayName: name.isEmpty,
      customHabitOrder: _customOrder,
    );
    try {
      await widget.gateway.saveWidgetConfiguration(configuration);
      if (!mounted || widget.configurationLaunch) return;
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.widgetSaveFailed)));
    }
  }

  Future<void> _cancel() async {
    if (widget.configurationLaunch) {
      await widget.gateway.cancelWidgetConfiguration();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: !widget.configurationLaunch,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_cancel());
    },
    child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _saving ? null : _cancel),
        title: Text(context.l10n.widgetBasicTitle),
        actions: <Widget>[
          TextButton(
            key: const Key('widget-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.save),
          ),
        ],
      ),
      body: ListView(
        key: const Key('widget-basic-editor'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: <Widget>[
          HabiterPageIntro(
            title: context.l10n.widgetBasicTitle,
            subtitle: context.l10n.widgetBasicBody,
          ),
          const SizedBox(height: HabiterSpace.lg),
          _EditorSection(
            title: context.l10n.widgetSectionIdentity,
            children: <Widget>[
              TextField(
                controller: _nameController,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: context.l10n.widgetDisplayName,
                  hintText: context.l10n.widgetDisplayNameHint,
                ),
              ),
            ],
          ),
          _EditorSection(
            title: context.l10n.widgetSectionContent,
            children: <Widget>[
              _Dropdown<WidgetHabitFilter>(
                label: context.l10n.widgetHabitSelection,
                value: _draft.habitFilter,
                values: WidgetHabitFilter.values,
                text: (value) => switch (value) {
                  WidgetHabitFilter.allToday =>
                    context.l10n.widgetHabitsAllToday,
                  WidgetHabitFilter.openOnly =>
                    context.l10n.widgetHabitsOpenOnly,
                  WidgetHabitFilter.selected =>
                    context.l10n.widgetHabitsSelected,
                },
                onChanged: (value) =>
                    _update(_draft.copyWith(habitFilter: value)),
              ),
              if (_draft.habitFilter == WidgetHabitFilter.selected) ...<Widget>[
                const SizedBox(height: HabiterSpace.sm),
                if (_availableHabits.isEmpty)
                  Text(context.l10n.widgetNoSelectableHabits)
                else
                  ..._availableHabits.map(
                    (habit) => CheckboxListTile(
                      key: Key('widget-habit-${habit.id}'),
                      contentPadding: EdgeInsets.zero,
                      value: _draft.selectedHabitIds.contains(habit.id),
                      secondary: Text(habit.icon),
                      title: Text(habit.name),
                      onChanged: (selected) {
                        final ids = Set<String>.from(_draft.selectedHabitIds);
                        selected == true
                            ? ids.add(habit.id)
                            : ids.remove(habit.id);
                        _update(_draft.copyWith(selectedHabitIds: ids));
                      },
                    ),
                  ),
              ],
              const SizedBox(height: HabiterSpace.md),
              _Dropdown<WidgetSortMode>(
                label: context.l10n.widgetSort,
                value: _draft.sortMode,
                values: WidgetSortMode.values,
                text: (value) => switch (value) {
                  WidgetSortMode.asInHabiter => context.l10n.widgetSortHabiter,
                  WidgetSortMode.openFirst => context.l10n.widgetSortOpenFirst,
                  WidgetSortMode.custom => context.l10n.widgetSortCustom,
                },
                onChanged: (value) => _update(_draft.copyWith(sortMode: value)),
              ),
              if (_draft.sortMode == WidgetSortMode.custom) ...<Widget>[
                const SizedBox(height: HabiterSpace.sm),
                Text(
                  context.l10n.widgetSortCustomBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _customOrder.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final id = _customOrder.removeAt(oldIndex);
                      _customOrder.insert(newIndex, id);
                    });
                  },
                  itemBuilder: (context, index) {
                    final id = _customOrder[index];
                    final habit = _availableHabits.firstWhere(
                      (candidate) => candidate.id == id,
                    );
                    return ListTile(
                      key: ValueKey<String>(id),
                      contentPadding: EdgeInsets.zero,
                      leading: Text(habit.icon),
                      title: Text(habit.name),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle_rounded),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          _EditorSection(
            title: context.l10n.widgetSectionMode,
            children: <Widget>[
              _Dropdown<WidgetContentMode>(
                label: context.l10n.widgetMode,
                value: _draft.contentMode,
                values: WidgetContentMode.values,
                text: (value) => switch (value) {
                  WidgetContentMode.auto => context.l10n.widgetModeAuto,
                  WidgetContentMode.focus => context.l10n.widgetModeFocus,
                  WidgetContentMode.list => context.l10n.widgetModeList,
                  WidgetContentMode.minimal => context.l10n.widgetModeMinimal,
                },
                onChanged: (value) =>
                    _update(_draft.copyWith(contentMode: value)),
              ),
            ],
          ),
          _EditorSection(
            title: context.l10n.widgetSectionAppearance,
            children: <Widget>[
              _Dropdown<WidgetThemeMode>(
                label: context.l10n.widgetTheme,
                value: _draft.themeMode,
                values: const <WidgetThemeMode>[
                  WidgetThemeMode.system,
                  WidgetThemeMode.light,
                  WidgetThemeMode.dark,
                ],
                text: (value) => switch (value) {
                  WidgetThemeMode.system => context.l10n.themeSystem,
                  WidgetThemeMode.light => context.l10n.themeLight,
                  WidgetThemeMode.dark => context.l10n.themeDark,
                  WidgetThemeMode.custom => context.l10n.widgetAccentCustom,
                },
                onChanged: (value) =>
                    _update(_draft.copyWith(themeMode: value)),
              ),
              const SizedBox(height: HabiterSpace.md),
              _Dropdown<WidgetAccentMode>(
                label: context.l10n.widgetAccent,
                value: _draft.accentMode,
                values: WidgetAccentMode.values,
                text: (value) => switch (value) {
                  WidgetAccentMode.habiter => context.l10n.widgetAccentHabiter,
                  WidgetAccentMode.dynamicColor =>
                    context.l10n.widgetAccentDynamic,
                  WidgetAccentMode.custom => context.l10n.widgetAccentCustom,
                },
                onChanged: (value) =>
                    _update(_draft.copyWith(accentMode: value)),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.widgetShowProgress),
                value: _draft.showProgress,
                onChanged: (value) =>
                    _update(_draft.copyWith(showProgress: value)),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.widgetShowSchedule),
                value: !_draft.hiddenElements.contains(
                  WidgetElement.scheduleLabel,
                ),
                onChanged: (value) =>
                    _setElementVisible(WidgetElement.scheduleLabel, value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.widgetShowCompleted),
                value: _draft.showCompleted,
                onChanged: (value) =>
                    _update(_draft.copyWith(showCompleted: value)),
              ),
              _Dropdown<WidgetDensity>(
                label: context.l10n.widgetDensity,
                value: _draft.density,
                values: WidgetDensity.values,
                text: (value) => value == WidgetDensity.compact
                    ? context.l10n.widgetDensityCompact
                    : context.l10n.widgetDensityComfortable,
                onChanged: (value) => _update(_draft.copyWith(density: value)),
              ),
            ],
          ),
          _EditorSection(
            title: context.l10n.widgetSectionBehavior,
            children: <Widget>[
              _Dropdown<WidgetBackgroundAction>(
                label: context.l10n.widgetBackgroundTap,
                value: _draft.interactions.background,
                values: WidgetBackgroundAction.values,
                text: (value) => switch (value) {
                  WidgetBackgroundAction.today =>
                    context.l10n.widgetBackgroundToday,
                  WidgetBackgroundAction.nextHabit =>
                    context.l10n.widgetBackgroundNext,
                  WidgetBackgroundAction.app =>
                    context.l10n.widgetBackgroundApp,
                },
                onChanged: (value) => _update(
                  _draft.copyWith(
                    interactions: _draft.interactions.copyWith(
                      background: value,
                    ),
                  ),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.widgetOneTapCompletion),
                subtitle: Text(context.l10n.widgetOneTapCompletionBody),
                value: _draft.oneTapCompletion,
                onChanged: (value) =>
                    _update(_draft.copyWith(oneTapCompletion: value)),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.widgetShowUndo),
                value: _draft.completionSettings.showUndo,
                onChanged: (value) => _update(
                  _draft.copyWith(
                    completionSettings: _draft.completionSettings.copyWith(
                      showUndo: value,
                    ),
                  ),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.widgetCompletionFeedback),
                value:
                    _draft.completionSettings.feedback !=
                    WidgetCompletionFeedback.minimal,
                onChanged: (value) => _update(
                  _draft.copyWith(
                    completionSettings: _draft.completionSettings.copyWith(
                      feedback: value
                          ? WidgetCompletionFeedback.normal
                          : WidgetCompletionFeedback.minimal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          WidgetAdvancedEditor(
            configuration: _draft,
            habits: _availableHabits,
            onChanged: _update,
          ),
        ],
      ),
    ),
  );
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HabiterSpace.md),
    child: HabiterSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: HabiterSpace.md),
          ...children,
        ],
      ),
    ),
  );
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.text,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) text;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: values
        .map(
          (value) => DropdownMenuItem<T>(
            value: value,
            child: Text(text(value), overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(growable: false),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}
