import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../models/locked_app.dart';

class StorageService {
  static const _habitsKey = 'habiter_habits';
  static const _habitEntriesKey = 'habiter_habit_entries';
  static const _aiInsightsKey = 'habiter_ai_insights';
  static const _userPreferencesKey = 'habiter_user_preferences';
  static const _aiConfigKey = 'habiter_ai_config';
  static const _appLockConfigKey = 'habiter_app_lock_config';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // Habits
  static Future<List<Habit>> getHabits() async {
    final prefs = await _prefs();
    final stored = prefs.getString(_habitsKey);
    if (stored == null) return [];
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded.map((e) => Habit.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await _prefs();
    final data = jsonEncode(habits.map((h) => h.toMap()).toList());
    await prefs.setString(_habitsKey, data);
  }

  static Future<void> addHabit(Habit habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await saveHabits(habits);
  }

  static Future<void> updateHabit(String id, Map<String, dynamic> updates) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final existing = habits[index];
      final freqValue = updates['frequency'];
      HabitFrequency frequency = existing.frequency;
      if (freqValue is HabitFrequency) {
        frequency = freqValue;
      } else if (freqValue is String) {
        frequency = HabitFrequency.values.firstWhere(
          (f) => f.name == freqValue,
          orElse: () => existing.frequency,
        );
      }
      habits[index] = existing.copyWith(
        name: updates['name'] as String? ?? existing.name,
        description: updates['description'] as String? ?? existing.description,
        color: updates['color'] as String? ?? existing.color,
        icon: updates['icon'] as String? ?? existing.icon,
        frequency: frequency,
        targetCount: (updates['targetCount'] as num?)?.toInt() ?? existing.targetCount,
        category: updates['category'] as String? ?? existing.category,
        createdAt: updates['createdAt'] as DateTime? ?? existing.createdAt,
        isActive: updates['isActive'] as bool? ?? existing.isActive,
      );
      await saveHabits(habits);
    }
  }

  static Future<void> deleteHabit(String id) async {
    final habits = await getHabits();
    final filtered = habits.where((h) => h.id != id).toList();
    await saveHabits(filtered);

    final entries = await getHabitEntries();
    final filteredEntries = entries.where((e) => e.habitId != id).toList();
    await saveHabitEntries(filteredEntries);
  }

  // Habit entries
  static Future<List<HabitEntry>> getHabitEntries() async {
    final prefs = await _prefs();
    final stored = prefs.getString(_habitEntriesKey);
    if (stored == null) return [];
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded.map((e) => HabitEntry.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveHabitEntries(List<HabitEntry> entries) async {
    final prefs = await _prefs();
    final data = jsonEncode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(_habitEntriesKey, data);
  }

  static Future<void> addHabitEntry(HabitEntry entry) async {
    final entries = await getHabitEntries();
    final filtered = entries
        .where((e) => !(e.habitId == entry.habitId && e.date == entry.date))
        .toList();
    filtered.add(entry);
    await saveHabitEntries(filtered);
  }

  // AI insights
  static Future<List<AIInsight>> getAIInsights() async {
    final prefs = await _prefs();
    final stored = prefs.getString(_aiInsightsKey);
    if (stored == null) return [];
    final decoded = jsonDecode(stored) as List<dynamic>;
    return decoded.map((e) => AIInsight.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveAIInsights(List<AIInsight> insights) async {
    final prefs = await _prefs();
    final data = jsonEncode(insights.map((i) => i.toMap()).toList());
    await prefs.setString(_aiInsightsKey, data);
  }

  static Future<void> addAIInsight(AIInsight insight) async {
    final insights = await getAIInsights();
    insights.insert(0, insight);
    if (insights.length > 50) {
      insights.removeRange(50, insights.length);
    }
    await saveAIInsights(insights);
  }

  // User preferences
  static Future<UserPreferences> getUserPreferences() async {
    final prefs = await _prefs();
    final stored = prefs.getString(_userPreferencesKey);
    if (stored == null) {
      return UserPreferences(
        theme: ThemePreference.system,
        notifications: true,
        reminderTime: '20:00',
        aiInsights: true,
        language: 'en',
      );
    }
    return UserPreferences.fromMap(jsonDecode(stored) as Map<String, dynamic>);
  }

  static Future<void> saveUserPreferences(UserPreferences prefsToSave) async {
    final prefs = await _prefs();
    await prefs.setString(_userPreferencesKey, jsonEncode(prefsToSave.toMap()));
  }

  // AI config (minimal stub)
  static Future<Map<String, String>?> getAIConfig() async {
    final prefs = await _prefs();
    final stored = prefs.getString(_aiConfigKey);
    if (stored == null) return null;
    return (jsonDecode(stored) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value.toString()));
  }

  static Future<void> saveAIConfig(Map<String, String> config) async {
    final prefs = await _prefs();
    await prefs.setString(_aiConfigKey, jsonEncode(config));
  }

  static Future<void> clearAIConfig() async {
    final prefs = await _prefs();
    await prefs.remove(_aiConfigKey);
  }

  // App Lock config
  static Future<AppLockConfig> getAppLockConfig() async {
    final prefs = await _prefs();
    final stored = prefs.getString(_appLockConfigKey);
    if (stored == null) return const AppLockConfig();
    return AppLockConfig.fromMap(jsonDecode(stored) as Map<String, dynamic>);
  }

  static Future<void> saveAppLockConfig(AppLockConfig config) async {
    final prefs = await _prefs();
    await prefs.setString(_appLockConfigKey, jsonEncode(config.toMap()));
  }

  static Future<void> clearAll() async {
    final prefs = await _prefs();
    await prefs.remove(_habitsKey);
    await prefs.remove(_habitEntriesKey);
    await prefs.remove(_aiInsightsKey);
    await prefs.remove(_userPreferencesKey);
    await prefs.remove(_aiConfigKey);
    await prefs.remove(_appLockConfigKey);
  }
}
