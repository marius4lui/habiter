import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../services/ai_manager.dart';
import '../services/classly_client.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/habit_utils.dart';

class HabitProvider extends ChangeNotifier {
  HabitProvider();

  final _uuid = const Uuid();

  List<Habit> habits = [];
  List<HabitEntry> habitEntries = [];
  List<AIInsight> aiInsights = [];
  UserPreferences preferences = UserPreferences(
    theme: ThemePreference.system,
    notifications: true,
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

      debugPrint('HabitProvider: Initializing AIManager...');
      await AIManager.initialize();
      debugPrint('HabitProvider: AIManager initialized');

      debugPrint('HabitProvider: Initializing NotificationService...');
      await NotificationService.instance.initialize();
      debugPrint('HabitProvider: NotificationService initialized');

      // Set up notification action callback
      NotificationService.instance.setActionCallback(handleNotificationAction);

      debugPrint('HabitProvider: Loading habits from storage...');
      habits = await StorageService.getHabits();
      debugPrint('HabitProvider: Loaded ${habits.length} habits');

      debugPrint('HabitProvider: Loading habit entries from storage...');
      habitEntries = await StorageService.getHabitEntries();
      debugPrint('HabitProvider: Loaded ${habitEntries.length} entries');

      debugPrint('HabitProvider: Loading AI insights from storage...');
      aiInsights = await StorageService.getAIInsights();
      debugPrint('HabitProvider: Loaded ${aiInsights.length} insights');

      debugPrint('HabitProvider: Loading user preferences...');
      preferences = await StorageService.getUserPreferences();
      debugPrint('HabitProvider: Loaded preferences');

      // Schedule global notification if enabled
      if (preferences.notifications) {
        debugPrint('HabitProvider: Scheduling global notification...');
        await NotificationService.instance.scheduleGlobalDailyReminder(
          time: preferences.reminderTime,
          habits: habits,
        );
        debugPrint('HabitProvider: Global notification scheduled');
      }

      // Schedule individual habit notifications
      debugPrint('HabitProvider: Scheduling individual habit notifications...');
      for (final habit in habits) {
        if (habit.notificationEnabled && habit.notificationTime != null) {
          await NotificationService.instance.scheduleHabitNotification(habit);
        }
      }
      debugPrint('HabitProvider: Individual notifications scheduled');

      // Mock Data Initialization
      if (habits.isEmpty) {
        debugPrint('HabitProvider: Creating mock habit...');
        final mockHabit = Habit(
          id: _uuid.v4(),
          name: 'Drink Water',
          description: 'Stay hydrated! 💧',
          color: '0xFF4ECDC4', // Teal/Cyan accent for visibility
          icon: '💧',
          frequency: HabitFrequency.daily,
          targetCount: 8,
          category: 'Health',
          createdAt: DateTime.now(),
          isActive: true,
        );
        habits = [mockHabit];
        await StorageService.addHabit(mockHabit);
        debugPrint('HabitProvider: Mock habit created');
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

  Future<void> addHabit({
    required String name,
    String? description,
    required String category,
    required HabitFrequency frequency,
    required int targetCount,
    required String color,
    required String icon,
    List<int>? customDays,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      description: description,
      color: color,
      icon: icon,
      frequency: frequency,
      targetCount: targetCount,
      category: category,
      customDays: customDays,
      createdAt: DateTime.now(),
      isActive: true,
    );

    habits = [habit, ...habits];
    await StorageService.addHabit(habit);
    notifyListeners();
  }

  Future<void> updateHabit(String id, Habit updated) async {
    final index = habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    habits[index] = updated;
    await StorageService.updateHabit(id, updated.toMap());
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    // Cancel notification before deleting
    await NotificationService.instance.cancelHabitNotification(id);

    habits = habits.where((h) => h.id != id).toList();
    habitEntries = habitEntries.where((e) => e.habitId != id).toList();
    await StorageService.deleteHabit(id);
    notifyListeners();
  }

  /// Archive a habit (set isActive = false)
  Future<void> archiveHabit(String id) async {
    final index = habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    
    final archivedHabit = habits[index].copyWith(isActive: false);
    habits[index] = archivedHabit;
    await StorageService.updateHabit(id, archivedHabit.toMap());
    
    // Cancel notification for archived habit
    await NotificationService.instance.cancelHabitNotification(id);
    
    debugPrint('HabitProvider: Archived habit: ${archivedHabit.name}');
    notifyListeners();
  }

  Future<void> toggleHabitCompletion(String habitId, String date) async {
    final habitIndex = habits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) return;
    
    final habit = habits[habitIndex];
    final existingIndex = habitEntries.indexWhere(
      (entry) => entry.habitId == habitId && entry.date == date,
    );
    HabitEntry? entry;
    bool isNowCompleted = false;
    
    if (existingIndex != -1) {
      final current = habitEntries[existingIndex];
      isNowCompleted = !current.completed;
      entry = HabitEntry(
        id: current.id,
        habitId: habitId,
        date: date,
        completed: isNowCompleted,
        count: isNowCompleted ? 1 : 0,
        timestamp: DateTime.now(),
      );
      habitEntries[existingIndex] = entry;
    } else {
      isNowCompleted = true;
      entry = HabitEntry(
        id: _uuid.v4(),
        habitId: habitId,
        date: date,
        completed: true,
        count: 1,
        timestamp: DateTime.now(),
      );
      habitEntries.add(entry);
    }

    await StorageService.addHabitEntry(entry);
    
    // If this is a Classly habit and it's now completed, archive it
    if (isNowCompleted && habit.description == 'Imported from Classly') {
      debugPrint('HabitProvider: Archiving completed Classly habit: ${habit.name}');
      final archivedHabit = habit.copyWith(isActive: false);
      habits[habitIndex] = archivedHabit;
      await StorageService.updateHabit(habitId, archivedHabit.toMap());
    }
    
    notifyListeners();
  }

  HabitStats getHabitStats(String habitId) {
    final habit = habits.firstWhere((h) => h.id == habitId);
    return calculateHabitStats(habit, habitEntries);
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
        provider: provider, apiKey: apiKey, model: model);
    notifyListeners();
  }

  Future<void> generateInsights() async {
    await AIManager.generateInsights(
      habits: habits,
      entries: habitEntries,
      addInsight: addAIInsight,
    );
  }

  /// Handle notification action to mark habit complete
  Future<void> handleNotificationAction(String habitId, String date) async {
    await toggleHabitCompletion(habitId, date);
  }

  /// Import Classly events as daily habits
  Future<int> importFromClasslyEvents(List<ClasslyEvent> events) async {
    int imported = 0;
    // Check ALL habits (including archived) to avoid re-importing completed tasks
    final existingNames = habits.map((h) => h.name.toLowerCase()).toSet();
    
    for (final event in events) {
      // Skip events without date (not relevant for habit tracking)
      if (event.date == null) continue;
      
      // Skip INFO type events - they are just informational, not actionable tasks
      if (event.type.toLowerCase() == 'info') continue;
      
      // Create habit name from event
      final name = event.title ?? event.subjectName ?? 'Classly Task';
      
      // Skip if habit with same name already exists
      if (existingNames.contains(name.toLowerCase())) continue;
      
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
      
      final habit = Habit(
        id: _uuid.v4(),
        name: name,
        description: 'Imported from Classly',
        color: '#4ECDC4', // Teal
        icon: icon,
        frequency: HabitFrequency.custom, // One-time event
        customDays: [], // Empty = doesn't repeat on any day
        targetCount: 1,
        category: event.subjectName ?? 'Classly',
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      habits = [habit, ...habits];
      await StorageService.addHabit(habit);
      existingNames.add(name.toLowerCase());
      imported++;
    }
    
    if (imported > 0) {
      notifyListeners();
    }
    return imported;
  }
}
