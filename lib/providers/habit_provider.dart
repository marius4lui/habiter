import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../services/ai_manager.dart';
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

      await AIManager.initialize();
      await NotificationService.instance.initialize();
      
      // Set up notification action callback
      NotificationService.instance.setActionCallback(handleNotificationAction);
      
      habits = await StorageService.getHabits();
      habitEntries = await StorageService.getHabitEntries();
      aiInsights = await StorageService.getAIInsights();
      preferences = await StorageService.getUserPreferences();

      // Schedule global notification if enabled
      if (preferences.notifications) {
        await NotificationService.instance.scheduleGlobalDailyReminder(
          time: preferences.reminderTime,
          habits: habits,
        );
      }
      
      // Schedule individual habit notifications
      for (final habit in habits) {
        if (habit.notificationEnabled && habit.notificationTime != null) {
          await NotificationService.instance.scheduleHabitNotification(habit);
        }
      }

      // Mock Data Initialization
      if (habits.isEmpty) {
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
      }

      loading = false;
      error = null;
    } catch (e) {
      error = 'Failed to load data';
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

  Future<void> toggleHabitCompletion(String habitId, String date) async {
    final existingIndex = habitEntries.indexWhere(
      (entry) => entry.habitId == habitId && entry.date == date,
    );
    HabitEntry? entry;
    if (existingIndex != -1) {
      final current = habitEntries[existingIndex];
      entry = HabitEntry(
        id: current.id,
        habitId: habitId,
        date: date,
        completed: !current.completed,
        count: current.completed ? 0 : 1,
        timestamp: DateTime.now(),
      );
      habitEntries[existingIndex] = entry;
    } else {
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
    await AIManager.saveConfig(provider: provider, apiKey: apiKey, model: model);
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
}
