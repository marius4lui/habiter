import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/ids/id_generator.dart';
import '../core/persistence/key_value_store.dart';
import '../core/platform/notification_gateway.dart';
import '../core/time/clock.dart';
import '../core/time/local_date.dart';
import '../features/analytics/application/analytics_controller.dart';
import '../features/analytics/domain/habit_metrics.dart';
import '../features/data_portability/data_portability_service.dart';
import '../features/habits/application/habit_repository.dart';
import '../features/habits/application/habits_controller.dart';
import '../features/habits/data/key_value_habit_repository.dart';
import '../features/habits/domain/habit_source.dart';
import '../features/history/application/history_controller.dart';
import '../features/history/application/habit_lifecycle_reminder_gateway.dart';
import '../features/reminders/application/reminder_coordinator.dart';
import '../features/reminders/application/reminder_setup_service.dart';
import '../features/reminders/domain/availability_profile.dart';
import '../features/reminders/domain/calibration_session.dart';
import '../features/reminders/domain/reminder_plan.dart';
import '../features/reminders/domain/reminder_policy.dart';
import '../features/reminders/domain/reminder_preferences.dart';
import '../features/today/application/today_controller.dart';
import '../features/today/application/completion_use_case.dart';
import '../models/habit.dart';
import '../services/ai_manager.dart';
import '../services/classly_client.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class HabitProvider extends ChangeNotifier {
  HabitProvider({
    HabitRepository? repository,
    Clock clock = const SystemClock(),
    IdGenerator ids = const UuidIdGenerator(),
    HabitLifecycleReminderGateway? lifecycleReminders,
    KeyValueStore? actionStore,
    NotificationGateway? notificationGateway,
    ReminderCoordinator? reminderCoordinator,
    Future<bool> Function()? requestReminderPermission,
    Future<void> Function()? synchronizeWidget,
  }) {
    _clock = clock;
    _ids = ids;
    final fallbackStore = _ProviderSharedPreferencesStore();
    final resolvedRepository =
        repository ?? KeyValueHabitRepository(fallbackStore);
    _repository = resolvedRepository;
    _habitsController = HabitsController(
      repository: resolvedRepository,
      ids: ids,
      clock: clock,
    );
    _historyController = HistoryController(resolvedRepository);
    _todayController = TodayController(
      repository: resolvedRepository,
      ids: ids,
      clock: clock,
      onChanged: _reloadHabitState,
    );
    _analyticsController = AnalyticsController(clock);
    _lifecycleReminders = lifecycleReminders ?? const _NoopLifecycleReminders();
    final reminderStore = actionStore ?? fallbackStore;
    _reminders =
        reminderCoordinator ??
        ReminderCoordinator(
          store: reminderStore,
          notifications: notificationGateway ?? NotificationService.instance,
          clock: clock,
          ids: ids,
          complete: _todayController.complete,
        );
    NotificationService.instance.setActionCallback((_, _) async {
      await reconcileReminders(processActions: true);
      notifyListeners();
    });
    _requestReminderPermission =
        requestReminderPermission ?? _requestNativeReminderPermission;
    _synchronizeWidget = synchronizeWidget;
    _habitsController.addListener(notifyListeners);
    _historyController.addListener(notifyListeners);
  }

  late final HabitsController _habitsController;
  late final HabitRepository _repository;
  late final HistoryController _historyController;
  late final TodayController _todayController;
  late final AnalyticsController _analyticsController;
  late final HabitLifecycleReminderGateway _lifecycleReminders;
  late final ReminderCoordinator _reminders;
  late final Clock _clock;
  late final IdGenerator _ids;
  late final Future<bool> Function() _requestReminderPermission;
  Future<void> Function()? _synchronizeWidget;

  List<Habit> get habits => _habitsController.state.habits;
  List<HabitEntry> get habitEntries => _historyController.state.entries;
  List<AIInsight> aiInsights = [];
  UserPreferences preferences = UserPreferences(
    theme: ThemePreference.system,
    notifications: false,
    reminderTime: '20:00',
    aiInsights: false,
    language: 'en',
  );

  ReminderPreferences get reminderPreferences => _reminders.preferences;
  Map<String, HabitReminderPolicy> get reminderPolicies => _reminders.policies;
  CalibrationSession? get calibrationSession => _reminders.calibration;
  Map<String, AvailabilityProfile> get availabilityProfiles =>
      _reminders.profiles;
  List<PersistedPlannedReminder> get plannedReminders =>
      _reminders.plannedReminders;

  bool loading = true;
  String? error;

  Future<void> load() async {
    try {
      loading = true;
      notifyListeners();

      debugPrint('HabitProvider: Starting load...');

      debugPrint('HabitProvider: Loading habits from repository...');
      await _reloadHabitState();
      debugPrint('HabitProvider: Loaded ${habits.length} habits');
      debugPrint('HabitProvider: Loaded ${habitEntries.length} entries');

      debugPrint('HabitProvider: Loading AI insights from storage...');
      aiInsights = await StorageService.getAIInsights();
      debugPrint('HabitProvider: Loaded ${aiInsights.length} insights');

      debugPrint('HabitProvider: Loading user preferences...');
      preferences = await StorageService.getUserPreferences();
      debugPrint('HabitProvider: Loaded preferences');

      await _reminders.initialize(
        habits: habits,
        entries: habitEntries,
        legacySettings: LegacyReminderSettings(
          notificationsEnabled: preferences.notifications,
          reminderTime: preferences.reminderTime,
        ),
      );
      // Draining a completion action may refresh the habit repository. Use the
      // resulting snapshot for the final reconciliation.
      await _reminders.synchronize(habits: habits, entries: habitEntries);

      debugPrint('HabitProvider: Load complete!');
      loading = false;
      error = null;
    } catch (e, stackTrace) {
      debugPrint('HabitProvider.load() error: $e');
      debugPrint('Stack trace: $stackTrace');
      error = 'Failed to load data: $e';
      loading = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> _reloadHabitState() async {
    await Future.wait([_habitsController.load(), _historyController.load()]);
    await syncWidget();
  }

  Future<void> syncWidget() async {
    try {
      await _synchronizeWidget?.call();
    } catch (error) {
      debugPrint('HabitProvider: Widget sync failed safely: $error');
    }
  }

  Future<String> addHabit({
    String? id,
    required String name,
    String? description,
    required String category,
    required HabitFrequency frequency,
    required int targetCount,
    required String color,
    required String icon,
    List<int>? customDays,
    bool notificationEnabled = false,
    String? notificationTime,
  }) async {
    final result = await _habitsController.add(
      id: id,
      name: name,
      description: description,
      color: color,
      icon: icon,
      frequency: frequency,
      targetCount: targetCount,
      category: category,
      customDays: customDays,
      notificationEnabled: notificationEnabled,
      notificationTime: notificationTime,
    );
    await syncWidget();
    final habit = habits.where((item) => item.id == result).firstOrNull;
    if (habit != null) {
      await _reminders.ensurePolicyForNewHabit(habit);
      if (!_reminders.policies.containsKey(habit.id)) {
        await _reminders.applyLegacyHabitPolicy(habit);
      }
      await reconcileReminders();
    }
    return result;
  }

  static Future<bool> _requestNativeReminderPermission() async {
    await NotificationService.instance.initialize();
    return NotificationService.instance.requestPermissions();
  }

  Future<bool> requestHabitReminderPermission() => _requestReminderPermission();

  Future<void> scheduleHabitReminder(String habitId) async {
    final habit = habits.where((item) => item.id == habitId).firstOrNull;
    if (habit == null ||
        !habit.notificationEnabled ||
        habit.notificationTime == null) {
      return;
    }
    await _reminders.applyLegacyHabitPolicy(habit);
    await reconcileReminders();
  }

  Future<void> updateHabit(String id, Habit updated) async {
    if (!habits.any((habit) => habit.id == id)) return;
    await _habitsController.update(updated);
    await _reminders.applyLegacyHabitPolicy(updated);
    await reconcileReminders();
    await syncWidget();
  }

  Future<void> deleteHabit(String id) async {
    await _habitsController.delete(id);
    await _lifecycleReminders.cancelForHabit(id);
    await _reminders.deleteHabitData(id);
    await _historyController.load();
    await reconcileReminders();
    await syncWidget();
  }

  /// Archive a habit (set isActive = false)
  Future<void> archiveHabit(String id) async {
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit == null) return;
    final result = await _habitsController.archive(id);
    if (!result.changed) return;
    await _lifecycleReminders.cancelForHabit(id);
    await reconcileReminders();
    await syncWidget();

    debugPrint('HabitProvider: Archived habit: ${habit.name}');
  }

  Future<void> pauseHabit(String id) async {
    final result = await _habitsController.pause(id);
    if (result.changed) await _lifecycleReminders.cancelForHabit(id);
    if (result.changed) await reconcileReminders();
    if (result.changed) await syncWidget();
  }

  Future<void> resumeHabit(String id) async {
    final result = await _habitsController.resume(id);
    if (!result.changed) return;
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit != null) await _lifecycleReminders.scheduleForHabit(habit);
    await reconcileReminders();
    await syncWidget();
  }

  Future<void> restoreHabit(String id) async {
    final result = await _habitsController.restore(id);
    if (!result.changed) return;
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit != null) await _lifecycleReminders.scheduleForHabit(habit);
    await reconcileReminders();
    await syncWidget();
  }

  Future<void> toggleHabitCompletion(String habitId, String date) async {
    final wasCompleted = habitEntries.any(
      (entry) =>
          entry.habitId == habitId && entry.date == date && entry.completed,
    );
    await _todayController.toggle(habitId, date);
    if (wasCompleted) {
      await _reminders.removeToggleCompletionSignal(habitId, date);
    } else {
      final occurredAt = _clock.now();
      await _reminders.recordCompletion(
        habitId: habitId,
        occurredAt: occurredAt,
        signalId:
            'toggle:$habitId:$date:${occurredAt.toUtc().toIso8601String()}',
      );
    }
    await reconcileReminders();
  }

  Future<CompletionResult> completeHabit(String habitId, String date) async {
    final result = await _todayController.complete(habitId, date);
    if (result.changed) {
      final committedAt = result.undoToken!.committedAt;
      await _reminders.recordCompletion(
        habitId: habitId,
        occurredAt: committedAt,
        signalId:
            'completion:$habitId:$date:${committedAt.toUtc().toIso8601String()}',
      );
      await reconcileReminders();
    }
    return result;
  }

  Future<CompletionResult> undoCompletion(CompletionUndoToken token) async {
    final result = await _todayController.undo(token);
    if (result.changed) {
      await _reminders.removeCompletionSignal(token);
      await reconcileReminders();
    }
    return result;
  }

  HabitStats getHabitStats(String habitId) {
    final habit = habits.firstWhere((h) => h.id == habitId);
    return _analyticsController.statsFor(habit, habitEntries);
  }

  HabitMetrics getHabitMetrics(String habitId) {
    final habit = habits.firstWhere((item) => item.id == habitId);
    return _analyticsController.metricsFor(habit, habitEntries);
  }

  Future<void> addAIInsight(AIInsight insight) async {
    aiInsights = [insight, ...aiInsights];
    await StorageService.addAIInsight(insight);
    notifyListeners();
  }

  Future<void> markInsightAsRead(String id) async {
    final index = aiInsights.indexWhere((i) => i.id == id);
    if (index == -1) return;
    aiInsights[index] = AIInsight(
      id: aiInsights[index].id,
      habitId: aiInsights[index].habitId,
      type: aiInsights[index].type,
      title: aiInsights[index].title,
      message: aiInsights[index].message,
      confidence: aiInsights[index].confidence,
      createdAt: aiInsights[index].createdAt,
      isRead: true,
    );
    await StorageService.saveAIInsights(aiInsights);
    notifyListeners();
  }

  Future<void> updatePreferences(UserPreferences prefs) async {
    final oldPrefs = preferences;
    preferences = prefs;
    await StorageService.saveUserPreferences(prefs);

    if (prefs.notifications != oldPrefs.notifications ||
        prefs.reminderTime != oldPrefs.reminderTime) {
      await _reminders.applyLegacyOverviewSettings(
        enabled: prefs.notifications,
        time: prefs.reminderTime,
      );
      await reconcileReminders();
    }

    if (prefs.language != oldPrefs.language || prefs.theme != oldPrefs.theme) {
      await syncWidget();
    }

    notifyListeners();
  }

  Future<String> exportData() => DataPortabilityService(
    _repository,
  ).exportJson(settings: preferences.toMap());

  Future<ImportPreview> previewImport(String input) =>
      DataPortabilityService(_repository).preview(input);

  Future<String> importData(
    String input, {
    ImportCollisionPolicy collisions = ImportCollisionPolicy.keepExisting,
  }) async {
    final backup = await DataPortabilityService(
      _repository,
    ).importJson(input, collisions: collisions);
    await _reloadHabitState();
    notifyListeners();
    return backup;
  }

  Future<void> configureAI({
    required String provider,
    required String apiKey,
    String? model,
  }) async {
    await AIManager.saveConfig(
      provider: provider,
      apiKey: apiKey,
      model: model,
    );
    notifyListeners();
  }

  Future<void> generateInsights() async {
    await AIManager.initialize();
    await AIManager.generateInsights(
      habits: habits,
      entries: habitEntries,
      addInsight: addAIInsight,
    );
  }

  Future<void> reconcileReminders({bool processActions = false}) =>
      _reminders.synchronize(
        habits: habits,
        entries: habitEntries,
        processActions: processActions,
      );

  Future<void> updateReminderPolicy(HabitReminderPolicy policy) async {
    await _reminders.updatePolicy(policy);
    notifyListeners();
  }

  Future<void> updateReminderPreferences(ReminderPreferences value) async {
    await _reminders.updatePreferences(value);
    notifyListeners();
  }

  Future<bool> enableSmartReminders({bool requestPermission = true}) async {
    if (requestPermission && !await requestHabitReminderPermission()) {
      return false;
    }
    await _reminders.enableSmartForNewUser(sessionId: _ids.next());
    notifyListeners();
    return true;
  }

  Future<void> markReminderIntroductionSeen() async {
    await _reminders.updatePreferences(
      reminderPreferences.copyWith(existingUserIntroductionSeen: true),
    );
    notifyListeners();
  }

  Future<void> pauseCalibration() async {
    await _reminders.pauseCalibration();
    notifyListeners();
  }

  Future<void> resumeCalibration() async {
    await _reminders.resumeCalibration();
    notifyListeners();
  }

  Future<void> restartCalibration() async {
    await _reminders.restartCalibration(sessionId: _ids.next());
    notifyListeners();
  }

  Future<void> resetReminderLearning() async {
    await _reminders.resetLearning();
    notifyListeners();
  }

  /// Import Classly events as daily habits
  Future<int> importFromClasslyEvents(List<ClasslyEvent> events) async {
    int imported = 0;
    // Check ALL habits (including archived) to avoid re-importing completed tasks
    final existingEventIds = habits
        .map((habit) => habit.source.externalId)
        .whereType<String>()
        .toSet();

    for (final event in events) {
      // Skip events without date (not relevant for habit tracking)
      if (event.date == null) continue;

      // Skip INFO type events - they are just informational, not actionable tasks
      if (event.type.toLowerCase() == 'info') continue;

      // Create habit name from event
      final name = event.title ?? event.subjectName ?? 'Classly Task';

      if (existingEventIds.contains(event.id)) continue;

      // Determine icon based on event type
      String icon;
      switch (event.type.toLowerCase()) {
        case 'homework':
        case 'hausaufgabe':
          icon = '📚';
        case 'exam':
        case 'klausur':
        case 'test':
          icon = '📝';
        case 'presentation':
        case 'präsentation':
          icon = '🎤';
        default:
          icon = '📋';
      }

      await _habitsController.add(
        name: name,
        description: null,
        color: '#4ECDC4', // Teal
        icon: icon,
        frequency: HabitFrequency.custom, // One-time event
        customDays: <int>[event.date!.weekday],
        targetCount: 1,
        category: event.subjectName ?? 'Classly',
        source: HabitSourceMetadata(
          kind: HabitSourceKind.classlyCompatible,
          externalId: event.id,
          additionalFields: <String, Object?>{
            'occursOn': LocalDate.fromDateTime(event.date!).toString(),
          },
        ),
      );
      existingEventIds.add(event.id);
      imported++;
    }

    return imported;
  }

  @override
  void dispose() {
    _habitsController.removeListener(notifyListeners);
    _historyController.removeListener(notifyListeners);
    _habitsController.dispose();
    _historyController.dispose();
    super.dispose();
  }
}

final class _NoopLifecycleReminders implements HabitLifecycleReminderGateway {
  const _NoopLifecycleReminders();

  @override
  Future<void> cancelForHabit(String habitId) async {}

  @override
  Future<void> scheduleForHabit(Habit habit) async {}
}

final class _ProviderSharedPreferencesStore implements KeyValueStore {
  @override
  Future<bool> contains(String key) async =>
      (await SharedPreferences.getInstance()).containsKey(key);

  @override
  Future<Object?> read(String key) async =>
      (await SharedPreferences.getInstance()).get(key);

  @override
  Future<bool> remove(String key) async =>
      (await SharedPreferences.getInstance()).remove(key);

  @override
  Future<Map<String, Object?>> snapshot() async {
    final preferences = await SharedPreferences.getInstance();
    return <String, Object?>{
      for (final key in preferences.getKeys()) key: preferences.get(key),
    };
  }

  @override
  Future<void> write(String key, Object value) async {
    final preferences = await SharedPreferences.getInstance();
    final written = switch (value) {
      String value => preferences.setString(key, value),
      bool value => preferences.setBool(key, value),
      int value => preferences.setInt(key, value),
      double value => preferences.setDouble(key, value),
      List<String> value => preferences.setStringList(key, List.of(value)),
      _ => throw ArgumentError.value(value, 'value', 'Unsupported value.'),
    };
    if (!await written) throw StateError('SharedPreferences rejected "$key".');
  }
}
