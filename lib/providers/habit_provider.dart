import 'package:flutter/material.dart';

import '../core/ids/id_generator.dart';
import '../core/persistence/key_value_store.dart';
import '../core/persistence/shared_preferences_key_value_store.dart';
import '../core/time/clock.dart';
import '../core/time/local_date.dart';
import '../features/analytics/application/analytics_controller.dart';
import '../features/analytics/domain/habit_metrics.dart';
import '../features/habits/application/habit_repository.dart';
import '../features/habits/application/habits_controller.dart';
import '../features/habits/data/key_value_habit_repository.dart';
import '../features/habits/domain/habit_source.dart';
import '../features/history/application/history_controller.dart';
import '../features/history/application/habit_lifecycle_reminder_gateway.dart';
import '../features/reminders/application/reminder_action_inbox.dart';
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
  }) {
    _clock = clock;
    final resolvedRepository =
        repository ?? KeyValueHabitRepository(SharedPreferencesKeyValueStore());
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
    _lifecycleReminders =
        lifecycleReminders ?? const _LegacyLifecycleReminderGateway();
    _actionInbox = ReminderActionInbox(
      actionStore ?? SharedPreferencesKeyValueStore(),
    );
    _actionProcessor = ReminderActionProcessor(
      inbox: _actionInbox,
      clock: clock,
      complete: (habitId, date) async {
        await _todayController.complete(habitId, date);
      },
    );
    _habitsController.addListener(notifyListeners);
    _historyController.addListener(notifyListeners);
  }

  late final HabitsController _habitsController;
  late final HistoryController _historyController;
  late final TodayController _todayController;
  late final AnalyticsController _analyticsController;
  late final HabitLifecycleReminderGateway _lifecycleReminders;
  late final ReminderActionInbox _actionInbox;
  late final ReminderActionProcessor _actionProcessor;
  late final Clock _clock;

  List<Habit> get habits => _habitsController.state.habits;
  List<HabitEntry> get habitEntries => _historyController.state.entries;
  List<AIInsight> aiInsights = [];
  UserPreferences preferences = UserPreferences(
    theme: ThemePreference.system,
    notifications: false,
    reminderTime: '20:00',
    aiInsights: true,
    language: 'en',
  );

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
      await _actionProcessor.drain();

      debugPrint('HabitProvider: Loading AI insights from storage...');
      aiInsights = await StorageService.getAIInsights();
      debugPrint('HabitProvider: Loaded ${aiInsights.length} insights');

      debugPrint('HabitProvider: Loading user preferences...');
      preferences = await StorageService.getUserPreferences();
      debugPrint('HabitProvider: Loaded preferences');

      final hasHabitNotifications = habits.any(
        (habit) => habit.notificationEnabled && habit.notificationTime != null,
      );
      if (preferences.notifications || hasHabitNotifications) {
        await NotificationService.instance.initialize();
        NotificationService.instance.setActionCallback(
          handleNotificationAction,
        );
      }

      if (preferences.notifications) {
        debugPrint('HabitProvider: Scheduling global notification...');
        await NotificationService.instance.scheduleGlobalDailyReminder(
          time: preferences.reminderTime,
          habits: habits,
        );
        debugPrint('HabitProvider: Global notification scheduled');
      }

      // Schedule individual habit notifications
      if (hasHabitNotifications) {
        debugPrint(
          'HabitProvider: Scheduling individual habit notifications...',
        );
        for (final habit in habits) {
          if (habit.notificationEnabled && habit.notificationTime != null) {
            await NotificationService.instance.scheduleHabitNotification(habit);
          }
        }
        debugPrint('HabitProvider: Individual notifications scheduled');
      }

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
  }

  Future<void> addHabit({
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
    await _habitsController.add(
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
  }

  Future<void> updateHabit(String id, Habit updated) async {
    if (!habits.any((habit) => habit.id == id)) return;
    await _habitsController.update(updated);
  }

  Future<void> deleteHabit(String id) async {
    await _habitsController.delete(id);
    await _lifecycleReminders.cancelForHabit(id);
    await _historyController.load();
  }

  /// Archive a habit (set isActive = false)
  Future<void> archiveHabit(String id) async {
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit == null) return;
    final result = await _habitsController.archive(id);
    if (!result.changed) return;
    await _lifecycleReminders.cancelForHabit(id);

    debugPrint('HabitProvider: Archived habit: ${habit.name}');
  }

  Future<void> pauseHabit(String id) async {
    final result = await _habitsController.pause(id);
    if (result.changed) await _lifecycleReminders.cancelForHabit(id);
  }

  Future<void> resumeHabit(String id) async {
    final result = await _habitsController.resume(id);
    if (!result.changed) return;
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit != null &&
        habit.notificationEnabled &&
        habit.notificationTime != null) {
      await _lifecycleReminders.scheduleForHabit(habit);
    }
  }

  Future<void> restoreHabit(String id) async {
    final result = await _habitsController.restore(id);
    if (!result.changed) return;
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit != null &&
        habit.notificationEnabled &&
        habit.notificationTime != null) {
      await _lifecycleReminders.scheduleForHabit(habit);
    }
  }

  Future<void> toggleHabitCompletion(String habitId, String date) async {
    await _todayController.toggle(habitId, date);
  }

  Future<CompletionResult> completeHabit(String habitId, String date) =>
      _todayController.complete(habitId, date);

  Future<CompletionResult> undoCompletion(CompletionUndoToken token) =>
      _todayController.undo(token);

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

    // Handle notification changes
    if (prefs.notifications != oldPrefs.notifications ||
        prefs.reminderTime != oldPrefs.reminderTime) {
      if (prefs.notifications) {
        await NotificationService.instance.scheduleGlobalDailyReminder(
          time: prefs.reminderTime,
          habits: habits,
        );
      } else {
        await NotificationService.instance.cancelGlobalDailyReminder();
      }
    }

    notifyListeners();
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

  /// Handle notification action to mark habit complete
  Future<void> handleNotificationAction(String habitId, String date) async {
    await _actionInbox.enqueue(
      ReminderActionRecord(
        id: '$habitId@$date:complete',
        habitId: habitId,
        occurrence: LocalDate.parse(date),
        receivedAt: _clock.now().toUtc(),
      ),
    );
    await _actionProcessor.drain();
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

final class _LegacyLifecycleReminderGateway
    implements HabitLifecycleReminderGateway {
  const _LegacyLifecycleReminderGateway();

  @override
  Future<void> cancelForHabit(String habitId) =>
      NotificationService.instance.cancelHabitNotification(habitId);

  @override
  Future<void> scheduleForHabit(Habit habit) =>
      NotificationService.instance.scheduleHabitNotification(habit);
}
