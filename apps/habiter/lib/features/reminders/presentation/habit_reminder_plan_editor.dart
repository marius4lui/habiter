import 'package:flutter/material.dart';

import '../../../core/design_system/adaptive_presentation.dart';
import '../../../core/design_system/tokens.dart';
import '../../../models/habit.dart';
import '../domain/local_time.dart';
import '../domain/reminder_policy.dart';

class HabitReminderPlanEditor extends StatefulWidget {
  const HabitReminderPlanEditor({
    super.key,
    required this.habit,
    required this.policy,
    required this.onSave,
  });

  final Habit habit;
  final HabitReminderPolicy policy;
  final Future<void> Function(HabitReminderPolicy policy) onSave;

  static Future<void> show(
    BuildContext context, {
    required Habit habit,
    required HabitReminderPolicy? policy,
    required Future<void> Function(HabitReminderPolicy policy) onSave,
  }) {
    final now = DateTime.now();
    final fallbackTime = _parseLegacyTime(habit.notificationTime);
    final effective =
        policy ??
        HabitReminderPolicy.fixedTimes(
          habitId: habit.id,
          times: <LocalTime>[fallbackTime],
          now: now,
          enabled: habit.notificationEnabled,
        );
    return showHabiterAdaptivePane<void>(
      context: context,
      builder: (_) => HabitReminderPlanEditor(
        habit: habit,
        policy: effective,
        onSave: onSave,
      ),
    );
  }

  static LocalTime _parseLegacyTime(String? value) {
    try {
      return LocalTime.parse(value ?? '20:00');
    } on FormatException {
      return const LocalTime(20, 0);
    }
  }

  @override
  State<HabitReminderPlanEditor> createState() =>
      _HabitReminderPlanEditorState();
}

class _HabitReminderPlanEditorState extends State<HabitReminderPlanEditor> {
  late bool _enabled;
  late ReminderMode _mode;
  late ReminderIntensity _intensity;
  late PeakWindowSource _windowSource;
  late List<LocalTimeRange> _smartWindows;
  late bool _fineTuning;
  late LocalTimeRange _randomWindow;
  late int _randomCount;
  late Duration _randomSpacing;
  late List<LocalTime> _fixedTimes;
  late Duration _snooze;
  bool _saving = false;

  _EditorCopy get _copy => _EditorCopy.of(context);

  @override
  void initState() {
    super.initState();
    final policy = widget.policy;
    _enabled = policy.enabled;
    _mode = policy.mode;
    _intensity = policy.intensity;
    _windowSource = policy.smart?.windowSource ?? PeakWindowSource.learned;
    _smartWindows = List<LocalTimeRange>.from(
      policy.smart?.userPeakWindows ?? const <LocalTimeRange>[],
    );
    _fineTuning = policy.smart?.allowFineTuningQuestions ?? true;
    _randomWindow =
        policy.random?.window ??
        const LocalTimeRange(start: LocalTime(8, 0), end: LocalTime(22, 0));
    _randomCount = policy.random?.timesPerHabitDay ?? 1;
    _randomSpacing = policy.random?.minimumSpacing ?? const Duration(hours: 2);
    _fixedTimes = List<LocalTime>.from(
      policy.fixed?.times ?? const <LocalTime>[LocalTime(20, 0)],
    );
    _snooze = policy.snoozeDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.habit.name} · ${_copy.reminderPlan}'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_copy.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          HabiterSpace.md,
          HabiterSpace.sm,
          HabiterSpace.md,
          HabiterSpace.xxl,
        ),
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(_copy.enabled),
            subtitle: Text(_copy.rhythmDaysOnly),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: HabiterSpace.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ReminderMode>(
              segments: <ButtonSegment<ReminderMode>>[
                ButtonSegment(
                  value: ReminderMode.smart,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(_copy.smart),
                ),
                ButtonSegment(
                  value: ReminderMode.randomWithinWindow,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: Text(_copy.random),
                ),
                ButtonSegment(
                  value: ReminderMode.fixedTimes,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(_copy.fixed),
                ),
              ],
              selected: <ReminderMode>{_mode},
              onSelectionChanged: (values) =>
                  setState(() => _mode = values.single),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: HabiterSpace.lg),
          if (_mode == ReminderMode.smart) _buildSmart(),
          if (_mode == ReminderMode.randomWithinWindow) _buildRandom(),
          if (_mode == ReminderMode.fixedTimes) _buildFixed(),
          const Divider(height: HabiterSpace.xxl),
          DropdownButtonFormField<Duration>(
            initialValue: _snooze,
            decoration: InputDecoration(labelText: _copy.defaultSnooze),
            items: <int>[15, 30, 60]
                .map(
                  (minutes) => DropdownMenuItem<Duration>(
                    value: Duration(minutes: minutes),
                    child: Text(_copy.minutes(minutes)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _snooze = value ?? _snooze),
          ),
        ],
      ),
    );
  }

  Widget _buildSmart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_copy.intensity, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HabiterSpace.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ReminderIntensity>(
            segments: ReminderIntensity.values
                .map(
                  (value) => ButtonSegment(
                    value: value,
                    label: Text(_copy.intensityName(value)),
                  ),
                )
                .toList(),
            selected: <ReminderIntensity>{_intensity},
            onSelectionChanged: (values) =>
                setState(() => _intensity = values.single),
          ),
        ),
        const SizedBox(height: HabiterSpace.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<PeakWindowSource>(
            segments: <ButtonSegment<PeakWindowSource>>[
              ButtonSegment(
                value: PeakWindowSource.learned,
                label: Text(_copy.learned),
              ),
              ButtonSegment(
                value: PeakWindowSource.userDefined,
                label: Text(_copy.ownWindows),
              ),
            ],
            selected: <PeakWindowSource>{_windowSource},
            onSelectionChanged: (values) =>
                setState(() => _windowSource = values.single),
          ),
        ),
        if (_windowSource == PeakWindowSource.userDefined) ...[
          const SizedBox(height: HabiterSpace.md),
          for (var index = 0; index < _smartWindows.length; index++)
            _RangeTile(
              range: _smartWindows[index],
              onEdit: () => _editSmartWindow(index),
              onDelete: () => setState(() => _smartWindows.removeAt(index)),
            ),
          OutlinedButton.icon(
            onPressed: _addSmartWindow,
            icon: const Icon(Icons.add),
            label: Text(_copy.addWindow),
          ),
        ],
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(_copy.fineTuning),
          subtitle: Text(_copy.fineTuningBody),
          value: _fineTuning,
          onChanged: (value) => setState(() => _fineTuning = value),
        ),
      ],
    );
  }

  Widget _buildRandom() {
    return Column(
      children: [
        _RangeTile(range: _randomWindow, onEdit: _editRandomWindow),
        const SizedBox(height: HabiterSpace.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_copy.timesPerDay),
          subtitle: Slider(
            value: _randomCount.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            label: '$_randomCount',
            onChanged: (value) => setState(() => _randomCount = value.round()),
          ),
          trailing: Text('$_randomCount×'),
        ),
        DropdownButtonFormField<Duration>(
          initialValue: _randomSpacing,
          decoration: InputDecoration(labelText: _copy.minimumSpacing),
          items: <int>[30, 60, 90, 120, 180]
              .map(
                (minutes) => DropdownMenuItem<Duration>(
                  value: Duration(minutes: minutes),
                  child: Text(_copy.minutes(minutes)),
                ),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _randomSpacing = value ?? _randomSpacing),
        ),
      ],
    );
  }

  Widget _buildFixed() {
    return Column(
      children: [
        for (var index = 0; index < _fixedTimes.length; index++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: Text(_fixedTimes[index].toString()),
            onTap: () => _editFixedTime(index),
            trailing: IconButton(
              tooltip: _copy.delete,
              onPressed: _fixedTimes.length == 1
                  ? null
                  : () => setState(() => _fixedTimes.removeAt(index)),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        if (_fixedTimes.length < 6)
          OutlinedButton.icon(
            onPressed: _addFixedTime,
            icon: const Icon(Icons.add),
            label: Text(_copy.addTime),
          ),
      ],
    );
  }

  Future<LocalTime?> _pickTime(LocalTime initial) async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    return value == null ? null : LocalTime(value.hour, value.minute);
  }

  Future<LocalTimeRange?> _pickRange(LocalTimeRange initial) async {
    final start = await _pickTime(initial.start);
    if (start == null || !mounted) return null;
    final end = await _pickTime(initial.end);
    if (end == null || start.compareTo(end) >= 0) return null;
    return LocalTimeRange(start: start, end: end);
  }

  Future<void> _addSmartWindow() async {
    final range = await _pickRange(
      const LocalTimeRange(start: LocalTime(17, 0), end: LocalTime(20, 0)),
    );
    if (range != null && mounted) setState(() => _smartWindows.add(range));
  }

  Future<void> _editSmartWindow(int index) async {
    final range = await _pickRange(_smartWindows[index]);
    if (range != null && mounted) setState(() => _smartWindows[index] = range);
  }

  Future<void> _editRandomWindow() async {
    final range = await _pickRange(_randomWindow);
    if (range != null && mounted) setState(() => _randomWindow = range);
  }

  Future<void> _addFixedTime() async {
    final time = await _pickTime(const LocalTime(20, 0));
    if (time != null && mounted) {
      setState(
        () => _fixedTimes = <LocalTime>{..._fixedTimes, time}.toList()..sort(),
      );
    }
  }

  Future<void> _editFixedTime(int index) async {
    final time = await _pickTime(_fixedTimes[index]);
    if (time != null && mounted) {
      setState(() {
        _fixedTimes[index] = time;
        _fixedTimes = _fixedTimes.toSet().toList()..sort();
      });
    }
  }

  Future<void> _save() async {
    if (_mode == ReminderMode.smart &&
        _windowSource == PeakWindowSource.userDefined &&
        _smartWindows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_copy.windowRequired)));
      return;
    }
    try {
      final now = DateTime.now();
      final policy = HabitReminderPolicy(
        schemaVersion: widget.policy.schemaVersion,
        habitId: widget.habit.id,
        enabled: _enabled,
        mode: _mode,
        intensity: _intensity,
        smart: _mode == ReminderMode.smart
            ? SmartReminderConfig(
                windowSource: _windowSource,
                userPeakWindows: _windowSource == PeakWindowSource.userDefined
                    ? _smartWindows
                    : const <LocalTimeRange>[],
                allowFineTuningQuestions: _fineTuning,
              )
            : null,
        random: _mode == ReminderMode.randomWithinWindow
            ? RandomReminderConfig(
                window: _randomWindow,
                timesPerHabitDay: _randomCount,
                minimumSpacing: _randomSpacing,
              )
            : null,
        fixed: _mode == ReminderMode.fixedTimes
            ? FixedReminderConfig(_fixedTimes)
            : null,
        snoozeDuration: _snooze,
        createdAt: widget.policy.createdAt,
        updatedAt: now,
        additionalFields: widget.policy.additionalFields,
      );
      setState(() => _saving = true);
      await widget.onSave(policy);
      if (mounted) Navigator.of(context).pop();
    } on ArgumentError {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_copy.overlappingWindows)));
    }
  }
}

class _RangeTile extends StatelessWidget {
  const _RangeTile({required this.range, required this.onEdit, this.onDelete});

  final LocalTimeRange range;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.access_time_rounded),
    title: Text('${range.start}–${range.end}'),
    onTap: onEdit,
    trailing: onDelete == null
        ? const Icon(Icons.edit_outlined)
        : IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
  );
}

final class _EditorCopy {
  const _EditorCopy(this.de);
  factory _EditorCopy.of(BuildContext context) =>
      _EditorCopy(Localizations.localeOf(context).languageCode == 'de');
  final bool de;

  String get reminderPlan => de ? 'Erinnerungsplan' : 'Reminder plan';
  String get save => de ? 'Speichern' : 'Save';
  String get enabled => de ? 'Erinnerungen aktiv' : 'Reminders enabled';
  String get rhythmDaysOnly => de
      ? 'Nur an Tagen, an denen das Habit ansteht.'
      : 'Only on days when the habit is scheduled.';
  String get smart => 'Smart';
  String get random => de ? 'Zufall' : 'Random';
  String get fixed => de ? 'Fest' : 'Fixed';
  String get intensity => de ? 'Intensität' : 'Intensity';
  String intensityName(ReminderIntensity value) => switch (value) {
    ReminderIntensity.gentle => de ? 'Sanft' : 'Gentle',
    ReminderIntensity.balanced => de ? 'Ausgewogen' : 'Balanced',
    ReminderIntensity.persistent => de ? 'Hartnäckig' : 'Persistent',
  };
  String get learned => de ? 'Gelernt' : 'Learned';
  String get ownWindows => de ? 'Eigene Fenster' : 'Own windows';
  String get addWindow => de ? 'Zeitfenster hinzufügen' : 'Add time window';
  String get fineTuning => de ? 'Rückfragen erlauben' : 'Allow fine-tuning';
  String get fineTuningBody => de
      ? 'Nach Woche 1 werden 3–6 Fragen pro Woche in normale Reminder integriert.'
      : 'After week 1, 3–6 weekly questions are folded into normal reminders.';
  String get timesPerDay =>
      de ? 'Auslieferungen pro Habit-Tag' : 'Times per habit day';
  String get minimumSpacing => de ? 'Mindestabstand' : 'Minimum spacing';
  String get defaultSnooze => de ? 'Standard für „Später“' : 'Default snooze';
  String minutes(int value) => de ? '$value Minuten' : '$value minutes';
  String get addTime => de ? 'Uhrzeit hinzufügen' : 'Add time';
  String get delete => de ? 'Löschen' : 'Delete';
  String get windowRequired => de
      ? 'Füge mindestens ein eigenes Zeitfenster hinzu.'
      : 'Add at least one custom time window.';
  String get overlappingWindows => de
      ? 'Zeitfenster dürfen sich nicht überschneiden.'
      : 'Time windows must not overlap.';
}
