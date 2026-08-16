import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/design_system/components.dart';
import '../core/design_system/tokens.dart';
import '../features/reminders/domain/availability_profile.dart';
import '../features/reminders/domain/calibration_session.dart';
import '../features/reminders/domain/local_time.dart';
import '../features/reminders/domain/reminder_plan.dart';
import '../features/reminders/domain/reminder_policy.dart';
import '../features/reminders/domain/reminder_preferences.dart';
import '../features/reminders/presentation/habit_reminder_plan_editor.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class RhythmScreen extends StatefulWidget {
  const RhythmScreen({super.key});

  @override
  State<RhythmScreen> createState() => _RhythmScreenState();
}

class _RhythmScreenState extends State<RhythmScreen> {
  String? _selectedProfileHabitId;
  bool _activating = false;

  _RhythmCopy get _copy => _RhythmCopy.of(context);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits
        .where(
          (habit) => habit.lifecycleStatus != HabitLifecycleStatus.archived,
        )
        .toList(growable: false);
    final selectedHabit =
        habits
            .where((habit) => habit.id == _selectedProfileHabitId)
            .firstOrNull ??
        habits.firstOrNull;
    final profile = selectedHabit == null
        ? null
        : provider.availabilityProfiles['habit:${selectedHabit.id}'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        children: [
          HabiterContent(
            maxWidth: HabiterSize.wideContentMax,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HabiterPageIntro(
                  eyebrow: _copy.eyebrow,
                  title: _copy.title,
                  subtitle: _copy.subtitle,
                  trailing: IconButton.filledTonal(
                    tooltip: _copy.globalSettings,
                    onPressed: () => _showGlobalSettings(provider),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
                const SizedBox(height: HabiterSpace.lg),
                if (!_notificationPlatformSupported) ...[
                  _UnsupportedPlatformCard(copy: _copy),
                  const SizedBox(height: HabiterSpace.md),
                ],
                if (!provider
                    .reminderPreferences
                    .existingUserIntroductionSeen) ...[
                  _IntroductionCard(
                    copy: _copy,
                    onDismiss: provider.markReminderIntroductionSeen,
                  ),
                  const SizedBox(height: HabiterSpace.md),
                ],
                _CalibrationCard(
                  copy: _copy,
                  preferences: provider.reminderPreferences,
                  session: provider.calibrationSession,
                  confidence: profile?.confidence ?? 0,
                  activating: _activating,
                  onActivate: _notificationPlatformSupported
                      ? () => _activate(provider)
                      : null,
                  onPause: provider.pauseCalibration,
                  onResume: provider.resumeCalibration,
                  onRestart: () => _confirmRestart(provider),
                ),
                const SizedBox(height: HabiterSpace.lg),
                HabiterSectionHeader(
                  title: _copy.availabilityProfile,
                  subtitle: _copy.profileBody,
                ),
                const SizedBox(height: HabiterSpace.md),
                if (habits.isEmpty)
                  HabiterEmptyState(
                    icon: Icons.schedule_outlined,
                    title: _copy.noHabits,
                    body: _copy.noHabitsBody,
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey(selectedHabit?.id),
                    initialValue: selectedHabit?.id,
                    decoration: InputDecoration(labelText: _copy.habit),
                    items: [
                      for (final habit in habits)
                        DropdownMenuItem(
                          value: habit.id,
                          child: Text(habit.name),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedProfileHabitId = value),
                  ),
                  const SizedBox(height: HabiterSpace.md),
                  _AvailabilityChart(
                    copy: _copy,
                    profile: profile,
                    preferences: provider.reminderPreferences,
                  ),
                ],
                const SizedBox(height: HabiterSpace.lg),
                HabiterSectionHeader(
                  title: _copy.habitPlans,
                  subtitle: _copy.habitPlansBody,
                ),
                const SizedBox(height: HabiterSpace.md),
                if (habits.isEmpty)
                  Text(_copy.noPlans)
                else
                  for (final habit in habits) ...[
                    _HabitPlanCard(
                      copy: _copy,
                      habit: habit,
                      policy: provider.reminderPolicies[habit.id],
                      next: _nextFor(provider.plannedReminders, habit.id),
                      explanationsEnabled:
                          provider.reminderPreferences.showLearningExplanations,
                      onEdit: () => HabitReminderPlanEditor.show(
                        context,
                        habit: habit,
                        policy: provider.reminderPolicies[habit.id],
                        onSave: provider.updateReminderPolicy,
                      ),
                      onWhy: (reminder) => _showWhy(reminder, habit),
                    ),
                    const SizedBox(height: HabiterSpace.sm),
                  ],
                const SizedBox(height: HabiterSpace.lg),
                OutlinedButton.icon(
                  onPressed: () => _confirmReset(provider),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(_copy.resetLearning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _notificationPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  PersistedPlannedReminder? _nextFor(
    List<PersistedPlannedReminder> reminders,
    String habitId,
  ) {
    final now = DateTime.now();
    final matches =
        reminders
            .where(
              (item) =>
                  item.habitId == habitId && item.scheduledFor.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return matches.firstOrNull;
  }

  Future<void> _activate(HabitProvider provider) async {
    setState(() => _activating = true);
    final granted = await provider.enableSmartReminders();
    if (!mounted) return;
    setState(() => _activating = false);
    if (!granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_copy.permissionMissing)));
    }
  }

  Future<void> _showGlobalSettings(HabitProvider provider) =>
      _GlobalReminderSettings.show(
        context,
        value: provider.reminderPreferences,
        onSave: provider.updateReminderPreferences,
      );

  Future<void> _confirmRestart(HabitProvider provider) async {
    final confirmed = await _confirm(
      title: _copy.restartCalibration,
      body: _copy.restartCalibrationBody,
      action: _copy.restart,
    );
    if (confirmed) await provider.restartCalibration();
  }

  Future<void> _confirmReset(HabitProvider provider) async {
    final confirmed = await _confirm(
      title: _copy.resetLearning,
      body: _copy.resetLearningBody,
      action: _copy.deleteData,
    );
    if (confirmed) await provider.resetReminderLearning();
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_copy.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _showWhy(PersistedPlannedReminder reminder, Habit habit) =>
      showDialog<void>(
        context: context,
        builder: (context) =>
            _WhyReminderDialog(copy: _copy, habit: habit, reminder: reminder),
      );
}

class _UnsupportedPlatformCard extends StatelessWidget {
  const _UnsupportedPlatformCard({required this.copy});
  final _RhythmCopy copy;

  @override
  Widget build(BuildContext context) => HabiterSurface(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.phone_android_rounded),
        const SizedBox(width: HabiterSpace.sm2),
        Expanded(child: Text(copy.unsupportedPlatform)),
      ],
    ),
  );
}

class _IntroductionCard extends StatelessWidget {
  const _IntroductionCard({required this.copy, required this.onDismiss});
  final _RhythmCopy copy;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) => HabiterSurface(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.introductionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: HabiterSpace.sm),
        Text(copy.introductionBody),
        const SizedBox(height: HabiterSpace.sm),
        Wrap(
          spacing: HabiterSpace.sm,
          runSpacing: HabiterSpace.xs,
          children: [
            _InfoChip(icon: Icons.offline_bolt_outlined, label: copy.local),
            _InfoChip(icon: Icons.tune_rounded, label: copy.userControlled),
            _InfoChip(icon: Icons.pause_rounded, label: copy.pausable),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: onDismiss, child: Text(copy.understood)),
        ),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard({
    required this.copy,
    required this.preferences,
    required this.session,
    required this.confidence,
    required this.activating,
    required this.onActivate,
    required this.onPause,
    required this.onResume,
    required this.onRestart,
  });

  final _RhythmCopy copy;
  final ReminderPreferences preferences;
  final CalibrationSession? session;
  final double confidence;
  final bool activating;
  final VoidCallback? onActivate;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onRestart;

  @override
  Widget build(BuildContext context) {
    final status = session?.status ?? CalibrationStatus.notStarted;
    final active = status == CalibrationStatus.active;
    final paused = status == CalibrationStatus.paused;
    final coverage = session?.coveredBuckets.length ?? 0;
    final title = active
        ? copy.calibrationDay(session!.dayNumberAt(DateTime.now()))
        : paused
        ? copy.calibrationPaused
        : status == CalibrationStatus.completed
        ? copy.profileActive
        : copy.smartReady;
    return HabiterSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                active ? Icons.auto_awesome_rounded : Icons.schedule_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: HabiterSpace.sm2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: HabiterSpace.xs),
                    Text(
                      copy.confidence(
                        ProfileConfidenceLabel.fromScore(confidence),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (session != null) ...[
            const SizedBox(height: HabiterSpace.md),
            Wrap(
              spacing: HabiterSpace.sm,
              runSpacing: HabiterSpace.sm,
              children: [
                _MetricChip(
                  label: copy.answers,
                  value: '${session!.answeredPulseCount}',
                ),
                _MetricChip(label: copy.coverage, value: '$coverage'),
                _MetricChip(
                  label: copy.confidenceTitle,
                  value: '${(confidence * 100).round()} %',
                ),
              ],
            ),
          ],
          const SizedBox(height: HabiterSpace.md),
          if (!preferences.enabled)
            FilledButton.icon(
              onPressed: activating ? null : onActivate,
              icon: activating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              label: Text(copy.activateSmart),
            )
          else
            Wrap(
              spacing: HabiterSpace.sm,
              runSpacing: HabiterSpace.sm,
              children: [
                if (active)
                  OutlinedButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause_rounded),
                    label: Text(copy.pause),
                  ),
                if (paused)
                  FilledButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(copy.continueLabel),
                  ),
                OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(copy.recalibrate),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: Chip(label: Text('$label · $value')),
  );
}

class _AvailabilityChart extends StatelessWidget {
  const _AvailabilityChart({
    required this.copy,
    required this.profile,
    required this.preferences,
  });

  final _RhythmCopy copy;
  final AvailabilityProfile? profile;
  final ReminderPreferences preferences;

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return HabiterSurface(child: Text(copy.profileNotReady));
    }
    final weekday = _visibleBuckets(ProfileDayType.weekday);
    final weekend = _visibleBuckets(ProfileDayType.weekend);
    return HabiterSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileRow(label: copy.weekdays, buckets: weekday, copy: copy),
          const SizedBox(height: HabiterSpace.md),
          _ProfileRow(label: copy.weekend, buckets: weekend, copy: copy),
          const SizedBox(height: HabiterSpace.md),
          Text(
            copy.peakWindows(_peakWindows(weekday)),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: HabiterSpace.xs),
          Text(
            copy.profileOrigin(profile!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<ProfileBucketKey, ProfileBucket>> _visibleBuckets(
    ProfileDayType dayType,
  ) =>
      profile!.buckets.entries
          .where(
            (entry) =>
                entry.key.dayType == dayType &&
                entry.key.minuteOfDay >=
                    preferences.activeDayStart.minuteOfDay &&
                entry.key.minuteOfDay <= preferences.activeDayEnd.minuteOfDay,
          )
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  List<LocalTimeRange> _peakWindows(
    List<MapEntry<ProfileBucketKey, ProfileBucket>> entries,
  ) {
    final result = <LocalTimeRange>[];
    int? start;
    int? last;
    for (final entry in entries) {
      final qualifies =
          entry.value.combinedScore >= .65 && entry.value.confidence >= .45;
      if (qualifies && (last == null || entry.key.minuteOfDay == last + 30)) {
        start ??= entry.key.minuteOfDay;
        last = entry.key.minuteOfDay;
      } else {
        if (start != null && last != null && last > start) {
          result.add(
            LocalTimeRange(
              start: LocalTime.fromMinuteOfDay(start),
              end: LocalTime.fromMinuteOfDay((last + 30).clamp(0, 1439)),
            ),
          );
        }
        start = qualifies ? entry.key.minuteOfDay : null;
        last = qualifies ? entry.key.minuteOfDay : null;
      }
    }
    if (start != null && last != null && last > start) {
      result.add(
        LocalTimeRange(
          start: LocalTime.fromMinuteOfDay(start),
          end: LocalTime.fromMinuteOfDay((last + 30).clamp(0, 1439)),
        ),
      );
    }
    return result.take(2).toList(growable: false);
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.buckets,
    required this.copy,
  });

  final String label;
  final List<MapEntry<ProfileBucketKey, ProfileBucket>> buckets;
  final _RhythmCopy copy;

  @override
  Widget build(BuildContext context) {
    final description = buckets.isEmpty
        ? copy.noProfileData
        : buckets
              .where((entry) => entry.value.combinedScore >= .65)
              .map((entry) => LocalTime.fromMinuteOfDay(entry.key.minuteOfDay))
              .map((time) => time.toString())
              .join(', ');
    return Semantics(
      container: true,
      label: '$label. ${description.isEmpty ? copy.noPeak : description}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: HabiterSpace.sm),
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  for (final entry in buckets)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(end: 2),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            Theme.of(context).colorScheme.primary,
                            entry.value.combinedScore.clamp(0, 1),
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: HabiterSpace.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    buckets.isEmpty
                        ? '–'
                        : LocalTime.fromMinuteOfDay(
                            buckets.first.key.minuteOfDay,
                          ).toString(),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                  ),
                ),
                Expanded(
                  child: Text(
                    buckets.isEmpty
                        ? '–'
                        : LocalTime.fromMinuteOfDay(
                            buckets.last.key.minuteOfDay,
                          ).toString(),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitPlanCard extends StatelessWidget {
  const _HabitPlanCard({
    required this.copy,
    required this.habit,
    required this.policy,
    required this.next,
    required this.explanationsEnabled,
    required this.onEdit,
    required this.onWhy,
  });

  final _RhythmCopy copy;
  final Habit habit;
  final HabitReminderPolicy? policy;
  final PersistedPlannedReminder? next;
  final bool explanationsEnabled;
  final VoidCallback onEdit;
  final ValueChanged<PersistedPlannedReminder> onWhy;

  @override
  Widget build(BuildContext context) => HabiterSurface(
    onTap: onEdit,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(habit.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: HabiterSpace.sm2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(copy.policySummary(policy)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        const SizedBox(height: HabiterSpace.md),
        Text(
          next == null
              ? copy.noNextReminder
              : copy.nextReminder(
                  DateFormat.MMMEd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).add_Hm().format(next!.scheduledFor.toLocal()),
                ),
        ),
        if (next != null && explanationsEnabled) ...[
          const SizedBox(height: HabiterSpace.xs),
          Text(
            copy.reasonSummary(next!.reason, habit.name),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: HabiterSpace.sm),
          TextButton.icon(
            onPressed: () => onWhy(next!),
            icon: const Icon(Icons.help_outline_rounded),
            label: Text(copy.whyThisTime),
          ),
        ],
      ],
    ),
  );
}

class _WhyReminderDialog extends StatelessWidget {
  const _WhyReminderDialog({
    required this.copy,
    required this.habit,
    required this.reminder,
  });
  final _RhythmCopy copy;
  final Habit habit;
  final PersistedPlannedReminder reminder;

  @override
  Widget build(BuildContext context) {
    final reason = reminder.reason;
    return AlertDialog(
      title: Text(copy.whyThisTime),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.reasonSummary(reason, habit.name)),
            if (reason.window != null) ...[
              const SizedBox(height: HabiterSpace.md),
              _DialogFact(
                icon: Icons.access_time_rounded,
                text: copy.allowedWindow(reason.window!),
              ),
            ],
            if (reason.positiveExplicitSignals > 0) ...[
              const SizedBox(height: HabiterSpace.sm),
              _DialogFact(
                icon: Icons.thumb_up_alt_outlined,
                text: copy.positiveSignals(reason.positiveExplicitSignals),
              ),
            ],
            if (reason.negativeExplicitSignals > 0) ...[
              const SizedBox(height: HabiterSpace.sm),
              _DialogFact(
                icon: Icons.thumb_down_alt_outlined,
                text: copy.negativeSignals(reason.negativeExplicitSignals),
              ),
            ],
            const SizedBox(height: HabiterSpace.md),
            Text(
              copy.ignoredIsNeutral,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(copy.close),
        ),
      ],
    );
  }
}

class _DialogFact extends StatelessWidget {
  const _DialogFact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: HabiterSpace.sm),
      Expanded(child: Text(text)),
    ],
  );
}

class _GlobalReminderSettings extends StatefulWidget {
  const _GlobalReminderSettings({required this.value, required this.onSave});
  final ReminderPreferences value;
  final Future<void> Function(ReminderPreferences value) onSave;

  static Future<void> show(
    BuildContext context, {
    required ReminderPreferences value,
    required Future<void> Function(ReminderPreferences value) onSave,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _GlobalReminderSettings(value: value, onSave: onSave),
  );

  @override
  State<_GlobalReminderSettings> createState() =>
      _GlobalReminderSettingsState();
}

class _GlobalReminderSettingsState extends State<_GlobalReminderSettings> {
  late bool _enabled;
  late LocalTime _start;
  late LocalTime _end;
  late int _limit;
  late Duration _spacing;
  late List<LocalTimeRange> _quietHours;
  late bool _calibration;
  late bool _learning;
  late bool _explanations;
  bool _saving = false;

  _RhythmCopy get _copy => _RhythmCopy.of(context);

  @override
  void initState() {
    super.initState();
    final value = widget.value;
    _enabled = value.enabled;
    _start = value.activeDayStart;
    _end = value.activeDayEnd;
    _limit = value.globalDailyLimit;
    _spacing = value.globalMinimumSpacing;
    _quietHours = List.of(value.quietHours);
    _calibration = value.calibrationEnabled;
    _learning = value.ongoingLearningEnabled;
    _explanations = value.showLearningExplanations;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_copy.globalSettings),
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
          title: Text(_copy.remindersEnabled),
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
        ),
        _TimeTile(
          label: _copy.activeDayStart,
          value: _start,
          onTap: () => _pick((value) => _start = value, _start),
        ),
        _TimeTile(
          label: _copy.activeDayEnd,
          value: _end,
          onTap: () => _pick((value) => _end = value, _end),
        ),
        const SizedBox(height: HabiterSpace.sm),
        Text('${_copy.dailyLimit}: $_limit'),
        Slider(
          value: _limit.toDouble(),
          min: 1,
          max: 16,
          divisions: 15,
          label: '$_limit',
          onChanged: (value) => setState(() => _limit = value.round()),
        ),
        DropdownButtonFormField<Duration>(
          initialValue: _spacing,
          decoration: InputDecoration(labelText: _copy.globalSpacing),
          items: <int>[30, 60, 90, 120, 180]
              .map(
                (minutes) => DropdownMenuItem(
                  value: Duration(minutes: minutes),
                  child: Text(_copy.minutes(minutes)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _spacing = value ?? _spacing),
        ),
        const SizedBox(height: HabiterSpace.lg),
        Text(_copy.quietHours, style: Theme.of(context).textTheme.titleMedium),
        for (var index = 0; index < _quietHours.length; index++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bedtime_outlined),
            title: Text(
              '${_quietHours[index].start}–${_quietHours[index].end}',
            ),
            trailing: IconButton(
              tooltip: _copy.delete,
              onPressed: () => setState(() => _quietHours.removeAt(index)),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _addQuietHours,
          icon: const Icon(Icons.add),
          label: Text(_copy.addQuietHours),
        ),
        const Divider(height: HabiterSpace.xxl),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(_copy.calibrationQuestions),
          value: _calibration,
          onChanged: (value) => setState(() => _calibration = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(_copy.ongoingLearning),
          value: _learning,
          onChanged: (value) => setState(() => _learning = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(_copy.learningExplanations),
          value: _explanations,
          onChanged: (value) => setState(() => _explanations = value),
        ),
      ],
    ),
  );

  Future<void> _pick(ValueChanged<LocalTime> update, LocalTime initial) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (result != null && mounted) {
      setState(() => update(LocalTime(result.hour, result.minute)));
    }
  }

  Future<LocalTime?> _pickTime(LocalTime initial) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    return result == null ? null : LocalTime(result.hour, result.minute);
  }

  Future<void> _addQuietHours() async {
    final start = await _pickTime(const LocalTime(12, 0));
    if (start == null || !mounted) return;
    final end = await _pickTime(const LocalTime(13, 0));
    if (end == null || !mounted) return;
    setState(() => _quietHours.add(LocalTimeRange(start: start, end: end)));
  }

  Future<void> _save() async {
    try {
      final result = widget.value.copyWith(
        enabled: _enabled,
        activeDayStart: _start,
        activeDayEnd: _end,
        globalDailyLimit: _limit,
        globalMinimumSpacing: _spacing,
        quietHours: _quietHours,
        calibrationEnabled: _calibration,
        ongoingLearningEnabled: _learning,
        showLearningExplanations: _explanations,
      );
      setState(() => _saving = true);
      await widget.onSave(result);
      if (mounted) Navigator.pop(context);
    } on ArgumentError {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_copy.invalidTimeSettings)));
    }
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final LocalTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value.toString()),
    onTap: onTap,
  );
}

final class _RhythmCopy {
  const _RhythmCopy(this.de);
  factory _RhythmCopy.of(BuildContext context) =>
      _RhythmCopy(Localizations.localeOf(context).languageCode == 'de');
  final bool de;

  String get eyebrow => de ? 'LOKAL & ERKLÄRBAR' : 'LOCAL & EXPLAINABLE';
  String get title => de ? 'Rhythmus' : 'Rhythm';
  String get subtitle => de
      ? 'Habiter findet passende Momente, ohne Cloud, Tracking oder Blackbox.'
      : 'Habiter finds fitting moments without cloud, tracking, or a black box.';
  String get globalSettings => de ? 'Globale Einstellungen' : 'Global settings';
  String get unsupportedPlatform => de
      ? 'System-Notifications sind auf diesem Gerät nicht verfügbar. Deine Pläne und Profile bleiben sichtbar und bearbeitbar.'
      : 'System notifications are unavailable on this device. Your plans and profiles remain visible and editable.';
  String get introductionTitle =>
      de ? 'So funktioniert Smart' : 'How Smart works';
  String get introductionBody => de
      ? 'Eine siebentägige Kalibrierung fragt, wann ein Habit gerade passt. Antworten wiegen stärker als Erledigungen. Ignorierte Notifications sind neutral. Maximal acht Hinweise pro Tag, 08:00–22:00 Uhr, jederzeit pausierbar.'
      : 'A seven-day calibration asks when a habit fits. Answers outweigh completions. Ignored notifications stay neutral. Up to eight alerts daily, 08:00–22:00, and pausable anytime.';
  String get local => de ? 'Nur lokal' : 'On-device only';
  String get userControlled => de ? 'Du entscheidest' : 'You stay in control';
  String get pausable => de ? 'Pausierbar' : 'Pausable';
  String get understood => de ? 'Verstanden' : 'Got it';
  String get availabilityProfile =>
      de ? 'Verfügbarkeitsprofil' : 'Availability profile';
  String get profileBody => de
      ? 'Helle Felder bedeuten: Dieser Zeitraum passt wahrscheinlich besser.'
      : 'Brighter blocks mean this period is more likely to fit.';
  String get habit => 'Habit';
  String get noHabits => de ? 'Noch keine Habits' : 'No habits yet';
  String get noHabitsBody => de
      ? 'Lege ein Habit an, um einen Erinnerungsplan zu konfigurieren.'
      : 'Create a habit to configure a reminder plan.';
  String get habitPlans => de ? 'Pläne pro Habit' : 'Plans by habit';
  String get habitPlansBody => de
      ? 'Smart, zufällig oder feste Zeiten – der Habit-Rhythmus bestimmt die erlaubten Tage.'
      : 'Smart, random, or fixed times—the habit rhythm determines eligible days.';
  String get noPlans => de ? 'Keine Pläne vorhanden.' : 'No plans available.';
  String get smartReady => de ? 'Smart ist bereit' : 'Smart is ready';
  String calibrationDay(int day) =>
      de ? 'Kalibrierung · Tag $day von 7' : 'Calibration · day $day of 7';
  String get calibrationPaused =>
      de ? 'Kalibrierung pausiert' : 'Calibration paused';
  String get profileActive =>
      de ? 'Smart-Profil aktiv' : 'Smart profile active';
  String confidence(ProfileConfidenceLabel label) => switch (label) {
    ProfileConfidenceLabel.learning =>
      de ? 'Wir lernen noch' : 'Still learning',
    ProfileConfidenceLabel.earlyTrend => de ? 'Erste Tendenz' : 'Early trend',
    ProfileConfidenceLabel.good => de ? 'Gutes Profil' : 'Good profile',
    ProfileConfidenceLabel.stable => de ? 'Stabiles Profil' : 'Stable profile',
  };
  String get answers => de ? 'Antworten' : 'Answers';
  String get coverage => de ? 'Abdeckung' : 'Coverage';
  String get confidenceTitle => de ? 'Vertrauen' : 'Confidence';
  String get activateSmart => de ? 'Smart aktivieren' : 'Enable Smart';
  String get permissionMissing => de
      ? 'Notifications wurden nicht freigegeben. Deine Einstellungen bleiben unverändert.'
      : 'Notifications were not allowed. Your settings remain unchanged.';
  String get pause => de ? 'Pausieren' : 'Pause';
  String get continueLabel => de ? 'Fortsetzen' : 'Resume';
  String get recalibrate => de ? 'Neu kalibrieren' : 'Recalibrate';
  String get restartCalibration =>
      de ? 'Kalibrierung neu starten?' : 'Restart calibration?';
  String get restartCalibrationBody => de
      ? 'Die sieben Tage beginnen erneut. Bereits gelernte Signale bleiben erhalten.'
      : 'The seven days start again. Existing learned signals are retained.';
  String get restart => de ? 'Neu starten' : 'Restart';
  String get resetLearning =>
      de ? 'Lerndaten zurücksetzen' : 'Reset learning data';
  String get resetLearningBody => de
      ? 'Rohsignale, Profile, Kalibrierungsstatus und geplante Smart-Notifications werden gelöscht.'
      : 'Raw signals, profiles, calibration state, and scheduled Smart notifications will be deleted.';
  String get deleteData => de ? 'Daten löschen' : 'Delete data';
  String get cancel => de ? 'Abbrechen' : 'Cancel';
  String get weekdays => de ? 'Montag–Freitag' : 'Monday–Friday';
  String get weekend => de ? 'Samstag–Sonntag' : 'Saturday–Sunday';
  String get noProfileData =>
      de ? 'Noch keine Profildaten.' : 'No profile data yet.';
  String get profileNotReady => de
      ? 'Das lokale Profil wird nach der nächsten Planung angezeigt.'
      : 'The local profile will appear after the next planning run.';
  String get noPeak =>
      de ? 'Noch kein sicheres Peak Window.' : 'No confident peak window yet.';
  String peakWindows(List<LocalTimeRange> values) => values.isEmpty
      ? noPeak
      : '${de ? 'Peak Windows' : 'Peak windows'}: ${values.map((value) => '${value.start}–${value.end}').join(', ')}';
  String profileOrigin(AvailabilityProfile profile) =>
      profile.effectiveSamples == 0
      ? (de
            ? 'Kategorie-Preset – noch nicht genug eigene Daten.'
            : 'Category preset—not enough personal data yet.')
      : (de
            ? '${profile.effectiveSamples} gewichtete lokale Signale.'
            : '${profile.effectiveSamples} weighted local signals.');
  String policySummary(HabitReminderPolicy? policy) {
    if (policy == null) {
      return de ? 'Noch nicht konfiguriert' : 'Not configured yet';
    }
    if (!policy.enabled) return de ? 'Deaktiviert' : 'Disabled';
    return switch (policy.mode) {
      ReminderMode.smart => 'Smart · ${intensity(policy.intensity)}',
      ReminderMode.randomWithinWindow =>
        de ? 'Zufällig im Fenster' : 'Random within window',
      ReminderMode.fixedTimes => de ? 'Feste Zeiten' : 'Fixed times',
    };
  }

  String intensity(ReminderIntensity value) => switch (value) {
    ReminderIntensity.gentle => de ? 'sanft' : 'gentle',
    ReminderIntensity.balanced => de ? 'ausgewogen' : 'balanced',
    ReminderIntensity.persistent => de ? 'hartnäckig' : 'persistent',
  };
  String get noNextReminder =>
      de ? 'Kein nächster Reminder geplant' : 'No upcoming reminder planned';
  String nextReminder(String value) =>
      de ? 'Nächster Reminder: $value' : 'Next reminder: $value';
  String get whyThisTime => de ? 'Warum diese Zeit?' : 'Why this time?';
  String reasonSummary(ReminderReason reason, String habitName) =>
      switch (reason.code) {
        ReminderReasonCode.habitLearnedPeak =>
          de
              ? 'Für $habitName passt dieses Zeitfenster häufig gut.'
              : 'This time window often works well for $habitName.',
        ReminderReasonCode.globalLearnedPeak =>
          de
              ? 'Dein allgemeiner Rhythmus passt hier häufig gut.'
              : 'Your overall rhythm often fits here.',
        ReminderReasonCode.categoryPreset =>
          de
              ? 'Kategorie-Preset verwendet – noch nicht genug eigene Daten.'
              : 'Using the category preset—not enough personal data yet.',
        ReminderReasonCode.userDefinedWindow =>
          de
              ? 'Innerhalb deines eigenen Fensters optimiert.'
              : 'Optimized inside your own window.',
        ReminderReasonCode.generalDefault =>
          de
              ? 'Ein sicherer Startwert innerhalb deiner Wachzeit.'
              : 'A safe starting point inside your active day.',
        ReminderReasonCode.deterministicRandom =>
          de
              ? 'Deterministisch zufällig innerhalb deines Fensters.'
              : 'Deterministically randomized inside your window.',
        ReminderReasonCode.fixedTime =>
          de
              ? 'Von dir als feste Uhrzeit gewählt.'
              : 'A fixed time chosen by you.',
        ReminderReasonCode.calibrationUncertainty =>
          de
              ? 'Hier fehlt dem lokalen Profil noch eine klare Antwort.'
              : 'The local profile still needs a clearer answer here.',
        ReminderReasonCode.fineTuningUncertainty =>
          de
              ? 'Eine kurze Rückfrage klärt widersprüchliche Signale.'
              : 'A short question helps resolve conflicting signals.',
        ReminderReasonCode.snoozedByUser =>
          de ? 'Von dir auf später verschoben.' : 'Snoozed by you.',
        ReminderReasonCode.dailyOverview =>
          de ? 'Dein fester Tagesüberblick.' : 'Your fixed daily overview.',
      };
  String allowedWindow(LocalTimeRange value) => de
      ? 'Erlaubtes Fenster: ${value.start}–${value.end}'
      : 'Allowed window: ${value.start}–${value.end}';
  String positiveSignals(int value) =>
      de ? '$value-mal als gut bewertet.' : 'Rated as good $value times.';
  String negativeSignals(int value) => de
      ? '$value-mal als gerade unpassend bewertet.'
      : 'Rated as a bad moment $value times.';
  String get ignoredIsNeutral => de
      ? 'Nicht beantwortete oder weggewischte Notifications werden nie negativ gewertet.'
      : 'Unanswered or dismissed notifications are never treated as negative feedback.';
  String get close => de ? 'Schließen' : 'Close';
  String get save => de ? 'Speichern' : 'Save';
  String get remindersEnabled =>
      de ? 'Notifications insgesamt aktiv' : 'Notifications enabled';
  String get activeDayStart => de ? 'Aktiver Tag beginnt' : 'Active day starts';
  String get activeDayEnd => de ? 'Aktiver Tag endet' : 'Active day ends';
  String get dailyLimit => de ? 'Tageslimit' : 'Daily limit';
  String get globalSpacing =>
      de ? 'Globaler Mindestabstand' : 'Global minimum spacing';
  String get quietHours => de ? 'Ruhezeiten' : 'Quiet hours';
  String get addQuietHours => de ? 'Ruhezeit hinzufügen' : 'Add quiet hours';
  String get delete => de ? 'Löschen' : 'Delete';
  String get calibrationQuestions =>
      de ? 'Kalibrierungsfragen' : 'Calibration questions';
  String get ongoingLearning =>
      de ? 'Weiterlernen nach Woche 1' : 'Continue learning after week 1';
  String get learningExplanations =>
      de ? 'Lernerklärungen anzeigen' : 'Show learning explanations';
  String minutes(int value) => de ? '$value Minuten' : '$value minutes';
  String get addQuietHoursDefault => de ? 'Ruhezeit' : 'Quiet time';
  String get invalidTimeSettings => de
      ? 'Prüfe Wachzeit und überschneidungsfreie Ruhezeiten.'
      : 'Check the active day and non-overlapping quiet hours.';
}
