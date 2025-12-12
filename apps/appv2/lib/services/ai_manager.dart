import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';
import '../utils/habit_utils.dart';

class AIManager {
  AIManager._();

  static const _uuid = Uuid();
  static Map<String, String>? _config;

  static Future<void> loadConfig() async {
    _config ??= await StorageService.getAIConfig();
  }

  static bool get isConfigured => _config != null;

  static String? get provider => _config?['provider'];

  static Future<void> saveConfig({
    required String provider,
    required String apiKey,
    String? model,
  }) async {
    _config = {
      'provider': provider,
      'apiKey': apiKey,
      if (model != null) 'model': model,
    };
    await StorageService.saveAIConfig(_config!);
  }

  static Future<void> clearConfig() async {
    _config = null;
    await StorageService.clearAIConfig();
  }

  static Future<bool> initialize() async {
    await loadConfig();
    return isConfigured;
  }

  static Future<void> generateInsights({
    required List<Habit> habits,
    required List<HabitEntry> entries,
    required Future<void> Function(AIInsight insight) addInsight,
  }) async {
    if (!isConfigured || habits.isEmpty) return;

    final rng = Random();
    final habitWithBestStreak = habits.map((habit) {
      final streak = calculateStreak(habit.id, entries);
      return (habit: habit, streak: streak.currentStreak);
    }).fold<(Habit, int)?>(null, (prev, next) {
      if (prev == null || next.streak > prev.$2) {
        return (next.habit, next.streak);
      }
      return prev;
    });

    final strugglingHabit = habits.map((habit) {
      final stats = calculateHabitStats(habit, entries);
      return (habit: habit, completion: stats.completionRate);
    }).fold<(Habit, double)?>(null, (prev, next) {
      if (prev == null || next.completion < prev.$2) {
        return (next.habit, next.completion);
      }
      return prev;
    });

    final recommendations = [
      if (habitWithBestStreak != null)
        AIInsight(
          id: _uuid.v4(),
          habitId: habitWithBestStreak.$1.id,
          type: AIInsightType.motivation,
          title: 'Keep the streak alive',
          message:
              '${habitWithBestStreak.$1.name} is on a ${habitWithBestStreak.$2}-day streak. Protect it with a reminder or a smaller fallback version today.',
          confidence: 0.75,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      if (strugglingHabit != null)
        AIInsight(
          id: _uuid.v4(),
          habitId: strugglingHabit.$1.id,
          type: AIInsightType.analysis,
          title: 'Adjust the difficulty',
          message:
              '${strugglingHabit.$1.name} has a ${strugglingHabit.$2.toStringAsFixed(0)}% completion rate. Try reducing the target or pairing it with an existing routine.',
          confidence: 0.68,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      AIInsight(
        id: _uuid.v4(),
        type: AIInsightType.recommendation,
        title: 'Add one easy win',
        message:
            'Stack a 2-minute habit after an existing routine (e.g., deep breath after brushing teeth) to build momentum.',
        confidence: 0.6,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    ];

    for (final insight in recommendations) {
      await addInsight(insight);
    }

    // Occasionally create a predictive style insight
    if (habits.length > 1 && rng.nextBool()) {
      final habit = habits[rng.nextInt(habits.length)];
      final stats = calculateHabitStats(habit, entries);
      final prediction = AIInsight(
        id: _uuid.v4(),
        habitId: habit.id,
        type: AIInsightType.prediction,
        title: 'Next 7 days forecast',
        message:
            'Based on recent pace (${stats.completionRate.toStringAsFixed(0)}% success), expect ${stats.averagePerWeek.toStringAsFixed(1)} completions next week. Plan a buffer day.',
        confidence: 0.55,
        createdAt: DateTime.now(),
        isRead: false,
      );
      await addInsight(prediction);
    }
  }
}
