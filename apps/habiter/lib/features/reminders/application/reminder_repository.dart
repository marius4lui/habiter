import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../domain/availability_profile.dart';
import '../domain/calibration_session.dart';
import '../domain/reminder_policy.dart';
import '../domain/reminder_plan.dart';
import '../domain/reminder_preferences.dart';
import '../domain/reminder_signal.dart';

final class ReminderRepositorySnapshot {
  ReminderRepositorySnapshot({
    this.schemaVersion = currentSchemaVersion,
    ReminderPreferences? preferences,
    Iterable<HabitReminderPolicy> policies = const <HabitReminderPolicy>[],
    Iterable<ReminderSignal> signals = const <ReminderSignal>[],
    Iterable<AvailabilityProfile> profiles = const <AvailabilityProfile>[],
    this.calibration,
    Iterable<PersistedPlannedReminder> plannedReminders =
        const <PersistedPlannedReminder>[],
    Iterable<PendingReminderSnooze> pendingSnoozes =
        const <PendingReminderSnooze>[],
    this.legacyMigrationComplete = false,
    Iterable<String> processedActionIds = const <String>[],
    Map<String, Object?> additionalFields = const <String, Object?>{},
  }) : preferences = preferences ?? ReminderPreferences(),
       policies = UnmodifiableMapView<String, HabitReminderPolicy>(
         <String, HabitReminderPolicy>{
           for (final policy in policies) policy.habitId: policy,
         },
       ),
       signals = List<ReminderSignal>.unmodifiable(signals),
       profiles = UnmodifiableMapView<String, AvailabilityProfile>(
         <String, AvailabilityProfile>{
           for (final profile in profiles) profile.profileId: profile,
         },
       ),
       plannedReminders = List<PersistedPlannedReminder>.unmodifiable(
         plannedReminders,
       ),
       pendingSnoozes = List<PendingReminderSnooze>.unmodifiable(
         pendingSnoozes,
       ),
       processedActionIds = Set<String>.unmodifiable(processedActionIds),
       additionalFields = UnmodifiableMapView<String, Object?>(
         Map<String, Object?>.from(additionalFields),
       );

  static const currentSchemaVersion = 1;

  factory ReminderRepositorySnapshot.fromMap(Map<String, Object?> map) {
    const known = <String>{
      'schemaVersion',
      'preferences',
      'policies',
      'signals',
      'profiles',
      'calibration',
      'plannedReminders',
      'pendingSnoozes',
      'legacyMigrationComplete',
      'processedActionIds',
    };
    return ReminderRepositorySnapshot(
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      preferences: map['preferences'] is Map
          ? ReminderPreferences.fromMap(
              Map<String, Object?>.from(map['preferences']! as Map),
            )
          : ReminderPreferences(),
      policies: ((map['policies'] as List<Object?>?) ?? const <Object?>[]).map(
        (value) => HabitReminderPolicy.fromMap(
          Map<String, Object?>.from(value! as Map),
        ),
      ),
      signals: ((map['signals'] as List<Object?>?) ?? const <Object?>[]).map(
        (value) =>
            ReminderSignal.fromMap(Map<String, Object?>.from(value! as Map)),
      ),
      profiles: ((map['profiles'] as List<Object?>?) ?? const <Object?>[]).map(
        (value) => AvailabilityProfile.fromMap(
          Map<String, Object?>.from(value! as Map),
        ),
      ),
      calibration: map['calibration'] is Map
          ? CalibrationSession.fromMap(
              Map<String, Object?>.from(map['calibration']! as Map),
            )
          : null,
      plannedReminders:
          ((map['plannedReminders'] as List<Object?>?) ?? const <Object?>[])
              .map(
                (value) => PersistedPlannedReminder.fromMap(
                  Map<String, Object?>.from(value! as Map),
                ),
              ),
      pendingSnoozes:
          ((map['pendingSnoozes'] as List<Object?>?) ?? const <Object?>[]).map(
            (value) => PendingReminderSnooze.fromMap(
              Map<String, Object?>.from(value! as Map),
            ),
          ),
      legacyMigrationComplete: map['legacyMigrationComplete'] as bool? ?? false,
      processedActionIds:
          ((map['processedActionIds'] as List<Object?>?) ?? const <Object?>[])
              .whereType<String>(),
      additionalFields: Map<String, Object?>.from(map)
        ..removeWhere((key, _) => known.contains(key)),
    );
  }

  final int schemaVersion;
  final ReminderPreferences preferences;
  final Map<String, HabitReminderPolicy> policies;
  final List<ReminderSignal> signals;
  final Map<String, AvailabilityProfile> profiles;
  final CalibrationSession? calibration;
  final List<PersistedPlannedReminder> plannedReminders;
  final List<PendingReminderSnooze> pendingSnoozes;
  final bool legacyMigrationComplete;
  final Set<String> processedActionIds;
  final Map<String, Object?> additionalFields;

  Map<String, Object?> toMap() => <String, Object?>{
    ...additionalFields,
    'schemaVersion': schemaVersion,
    'preferences': preferences.toMap(),
    'policies': policies.values.map((policy) => policy.toMap()).toList(),
    'signals': signals.map((signal) => signal.toMap()).toList(),
    'profiles': profiles.values.map((profile) => profile.toMap()).toList(),
    if (calibration != null) 'calibration': calibration!.toMap(),
    'plannedReminders': plannedReminders
        .map((reminder) => reminder.toMap())
        .toList(),
    'pendingSnoozes': pendingSnoozes.map((snooze) => snooze.toMap()).toList(),
    'legacyMigrationComplete': legacyMigrationComplete,
    'processedActionIds': processedActionIds.toList()..sort(),
  };
}

final class ReminderRepositoryDraft {
  ReminderRepositoryDraft(ReminderRepositorySnapshot source)
    : schemaVersion = source.schemaVersion,
      preferences = source.preferences,
      policies = Map<String, HabitReminderPolicy>.from(source.policies),
      signals = List<ReminderSignal>.from(source.signals),
      profiles = Map<String, AvailabilityProfile>.from(source.profiles),
      calibration = source.calibration,
      plannedReminders = List<PersistedPlannedReminder>.from(
        source.plannedReminders,
      ),
      pendingSnoozes = List<PendingReminderSnooze>.from(source.pendingSnoozes),
      legacyMigrationComplete = source.legacyMigrationComplete,
      processedActionIds = Set<String>.from(source.processedActionIds),
      additionalFields = Map<String, Object?>.from(source.additionalFields);

  int schemaVersion;
  ReminderPreferences preferences;
  Map<String, HabitReminderPolicy> policies;
  List<ReminderSignal> signals;
  Map<String, AvailabilityProfile> profiles;
  CalibrationSession? calibration;
  List<PersistedPlannedReminder> plannedReminders;
  List<PendingReminderSnooze> pendingSnoozes;
  bool legacyMigrationComplete;
  Set<String> processedActionIds;
  Map<String, Object?> additionalFields;

  ReminderRepositorySnapshot freeze() => ReminderRepositorySnapshot(
    schemaVersion: schemaVersion,
    preferences: preferences,
    policies: policies.values,
    signals: signals,
    profiles: profiles.values,
    calibration: calibration,
    plannedReminders: plannedReminders,
    pendingSnoozes: pendingSnoozes,
    legacyMigrationComplete: legacyMigrationComplete,
    processedActionIds: processedActionIds,
    additionalFields: additionalFields,
  );
}

final class ReminderRepository {
  ReminderRepository(this._store);

  static const storageKey = 'habiter_smart_reminders_v1';
  static const rawSignalRetention = Duration(days: 180);

  final KeyValueStore _store;
  Future<void> _queue = Future<void>.value();

  Future<ReminderRepositorySnapshot> load() => _enqueue(_loadUnlocked);

  Future<void> transact(
    FutureOr<void> Function(ReminderRepositoryDraft draft) mutation,
  ) => _enqueue(() async {
    final draft = ReminderRepositoryDraft(await _loadUnlocked());
    await mutation(draft);
    await _write(draft.freeze());
  });

  Future<void> appendSignal(ReminderSignal signal) => transact((draft) {
    if (draft.signals.any((item) => item.id == signal.id)) return;
    draft.signals.add(signal);
  });

  Future<void> replaceProfiles(Iterable<AvailabilityProfile> profiles) =>
      transact((draft) {
        draft.profiles = <String, AvailabilityProfile>{
          for (final profile in profiles) profile.profileId: profile,
        };
      });

  Future<int> pruneRawSignals(DateTime now) async {
    var removed = 0;
    await transact((draft) {
      final cutoff = now.toUtc().subtract(rawSignalRetention);
      final retained = draft.signals
          .where((signal) => !signal.occurredAtUtc.isBefore(cutoff))
          .toList();
      removed = draft.signals.length - retained.length;
      draft.signals = retained;
    });
    return removed;
  }

  Future<void> resetLearning() => transact((draft) {
    draft.signals.clear();
    draft.profiles.clear();
    draft.calibration = null;
    draft.plannedReminders.removeWhere(
      (reminder) => reminder.kind != PlannedReminderKind.dailyOverview,
    );
    draft.pendingSnoozes.clear();
    draft.processedActionIds.clear();
  });

  Future<ReminderRepositorySnapshot> _loadUnlocked() async {
    final raw = await _store.read(storageKey);
    if (raw == null) return ReminderRepositorySnapshot();
    if (raw is! String) {
      throw const FormatException('Reminder storage must be JSON text.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Reminder storage must be a JSON object.');
    }
    return ReminderRepositorySnapshot.fromMap(
      Map<String, Object?>.from(decoded),
    );
  }

  Future<void> _write(ReminderRepositorySnapshot snapshot) =>
      _store.write(storageKey, jsonEncode(snapshot.toMap()));

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _queue = _queue.catchError((Object _) {}).then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
