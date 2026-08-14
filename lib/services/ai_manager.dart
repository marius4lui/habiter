import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';
import '../utils/habit_utils.dart';

abstract interface class AIKeyVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

final class SecureAIKeyVault implements AIKeyVault {
  const SecureAIKeyVault();
  static const _storage = FlutterSecureStorage();
  static const _key = 'experimental_ai_api_key';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Deterministic, on-device coaching. It performs no network requests.
final class LocalCoachingEngine {
  const LocalCoachingEngine();

  List<AIInsight> generate({
    required List<Habit> habits,
    required List<HabitEntry> entries,
    required DateTime now,
  }) {
    if (habits.isEmpty) return const <AIInsight>[];
    final ranked =
        habits
            .map(
              (habit) =>
                  (habit, calculateStreak(habit.id, entries).currentStreak),
            )
            .toList()
          ..sort((a, b) {
            final streak = b.$2.compareTo(a.$2);
            return streak != 0 ? streak : a.$1.id.compareTo(b.$1.id);
          });
    final best = ranked.first;
    return <AIInsight>[
      AIInsight(
        id: 'local:${best.$1.id}:${now.toUtc().toIso8601String().substring(0, 10)}',
        habitId: best.$1.id,
        type: AIInsightType.motivation,
        title: 'A gentle next step',
        message: best.$2 > 0
            ? '${best.$1.name} has ${best.$2} recent completions. A small version still counts today.'
            : 'Start ${best.$1.name} with the smallest useful version today.',
        confidence: 1,
        createdAt: now,
        isRead: false,
      ),
    ];
  }
}

/// Experimental remote configuration. Disabled unless a user explicitly opts in.
class AIManager {
  AIManager._();

  static AIKeyVault keyVault = const SecureAIKeyVault();
  static Map<String, String>? _config;

  static Future<void> loadConfig() async {
    final legacy = await StorageService.getAIConfig();
    final legacyKey = legacy?['apiKey'];
    if (legacyKey != null && legacyKey.isNotEmpty) {
      await keyVault.write(legacyKey);
      final sanitized = Map<String, String>.from(legacy!)..remove('apiKey');
      await StorageService.saveAIConfig(sanitized);
      _config = sanitized;
    } else {
      _config = legacy;
    }
  }

  static bool get isConfigured => _config?['enabled'] == 'true';
  static String? get provider => _config?['provider'];

  static Future<void> saveConfig({
    required String provider,
    required String apiKey,
    String? model,
  }) async {
    await keyVault.write(apiKey);
    _config = <String, String>{
      'provider': provider,
      'enabled': 'true',
      if (model != null) 'model': model,
    };
    await StorageService.saveAIConfig(_config!);
  }

  static Future<void> clearConfig() async {
    await keyVault.clear();
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
    final insights = const LocalCoachingEngine().generate(
      habits: habits,
      entries: entries,
      now: DateTime.now(),
    );
    for (final insight in insights) {
      await addInsight(insight);
    }
  }
}
