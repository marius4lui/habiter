import 'dart:convert';

const _unsetHabitField = Object();

enum HabitFrequency { daily, weekly, custom }

enum AIInsightType { recommendation, motivation, analysis, prediction }

enum ThemePreference { light, dark, system }

enum HabitLifecycleStatus { active, paused, archived }

final class HabitPause {
  const HabitPause({required this.startedAt, this.endedAt});

  final DateTime startedAt;
  final DateTime? endedAt;

  HabitPause end(DateTime value) =>
      HabitPause(startedAt: startedAt, endedAt: value);

  bool includesDate(String value) {
    final date = DateTime.parse('${value}T00:00:00Z');
    final start = DateTime.utc(startedAt.year, startedAt.month, startedAt.day);
    final end = endedAt == null
        ? null
        : DateTime.utc(endedAt!.year, endedAt!.month, endedAt!.day);
    return !date.isBefore(start) && (end == null || date.isBefore(end));
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };

  factory HabitPause.fromMap(Map<String, dynamic> map) => HabitPause(
    startedAt: DateTime.parse(map['startedAt'] as String),
    endedAt: map['endedAt'] == null
        ? null
        : DateTime.parse(map['endedAt'] as String),
  );
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    required this.frequency,
    required this.targetCount,
    required this.category,
    this.customDays,
    required this.createdAt,
    required this.isActive,
    this.notificationEnabled = false,
    this.notificationTime,
    Iterable<HabitPause> pauses = const <HabitPause>[],
    this.archivedAt,
    this.restoredAt,
  }) : pauses = List<HabitPause>.unmodifiable(pauses);

  final String id;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final HabitFrequency frequency;
  final int targetCount;
  final String category;
  final List<int>? customDays;
  final DateTime createdAt;
  final bool isActive;
  final bool notificationEnabled;
  final String? notificationTime;
  final List<HabitPause> pauses;
  final DateTime? archivedAt;
  final DateTime? restoredAt;

  HabitLifecycleStatus get lifecycleStatus {
    if (isActive) return HabitLifecycleStatus.active;
    if (pauses.isNotEmpty && pauses.last.endedAt == null) {
      return HabitLifecycleStatus.paused;
    }
    return HabitLifecycleStatus.archived;
  }

  bool isPausedOn(String date) =>
      pauses.any((pause) => pause.includesDate(date));

  Habit copyWith({
    String? id,
    String? name,
    Object? description = _unsetHabitField,
    String? color,
    String? icon,
    HabitFrequency? frequency,
    int? targetCount,
    String? category,
    Object? customDays = _unsetHabitField,
    DateTime? createdAt,
    bool? isActive,
    bool? notificationEnabled,
    Object? notificationTime = _unsetHabitField,
    Iterable<HabitPause>? pauses,
    Object? archivedAt = _unsetHabitField,
    Object? restoredAt = _unsetHabitField,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: identical(description, _unsetHabitField)
          ? this.description
          : description as String?,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      category: category ?? this.category,
      customDays: identical(customDays, _unsetHabitField)
          ? this.customDays
          : customDays as List<int>?,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTime: identical(notificationTime, _unsetHabitField)
          ? this.notificationTime
          : notificationTime as String?,
      pauses: pauses ?? this.pauses,
      archivedAt: identical(archivedAt, _unsetHabitField)
          ? this.archivedAt
          : archivedAt as DateTime?,
      restoredAt: identical(restoredAt, _unsetHabitField)
          ? this.restoredAt
          : restoredAt as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'frequency': frequency.name,
      'targetCount': targetCount,
      'category': category,
      'customDays': customDays,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'notificationEnabled': notificationEnabled,
      'notificationTime': notificationTime,
      if (pauses.isNotEmpty)
        'pauses': pauses.map((pause) => pause.toMap()).toList(growable: false),
      if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
      if (restoredAt != null) 'restoredAt': restoredAt!.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String,
      icon: map['icon'] as String,
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == map['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 1,
      category: map['category'] as String? ?? 'General',
      customDays: (map['customDays'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
      notificationEnabled: map['notificationEnabled'] as bool? ?? false,
      notificationTime: map['notificationTime'] as String?,
      pauses: ((map['pauses'] as List<dynamic>?) ?? const <dynamic>[]).map(
        (value) => HabitPause.fromMap(Map<String, dynamic>.from(value as Map)),
      ),
      archivedAt: DateTime.tryParse(map['archivedAt'] as String? ?? ''),
      restoredAt: DateTime.tryParse(map['restoredAt'] as String? ?? ''),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Habit.fromJson(String source) =>
      Habit.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class HabitEntry {
  HabitEntry({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    required this.count,
    required this.timestamp,
  });

  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd
  final bool completed;
  final int count;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date,
      'completed': completed,
      'count': count,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HabitEntry.fromMap(Map<String, dynamic> map) {
    return HabitEntry(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      date: map['date'] as String,
      completed: map['completed'] as bool? ?? false,
      count: (map['count'] as num?)?.toInt() ?? 0,
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class HabitStreak {
  HabitStreak({
    required this.habitId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
  });

  final String habitId;
  final int currentStreak;
  final int longestStreak;
  final String lastCompletedDate;
}

class HabitStats {
  HabitStats({
    required this.habitId,
    required this.totalCompletions,
    required this.completionRate,
    required this.averagePerWeek,
    required this.streakData,
  });

  final String habitId;
  final int totalCompletions;
  final double completionRate;
  final double averagePerWeek;
  final HabitStreak streakData;
}

class AIInsight {
  AIInsight({
    required this.id,
    this.habitId,
    required this.type,
    required this.title,
    required this.message,
    required this.confidence,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String? habitId;
  final AIInsightType type;
  final String title;
  final String message;
  final double confidence;
  final DateTime createdAt;
  final bool isRead;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'type': type.name,
      'title': title,
      'message': message,
      'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AIInsight.fromMap(Map<String, dynamic> map) {
    return AIInsight(
      id: map['id'] as String,
      habitId: map['habitId'] as String?,
      type: AIInsightType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => AIInsightType.analysis,
      ),
      title: map['title'] as String? ?? 'Insight',
      message: map['message'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}

class UserPreferences {
  UserPreferences({
    required this.theme,
    required this.notifications,
    required this.reminderTime,
    required this.aiInsights,
    required this.language,
  });

  final ThemePreference theme;
  final bool notifications;
  final String reminderTime;
  final bool aiInsights;
  final String language;

  Map<String, dynamic> toMap() {
    return {
      'theme': theme.name,
      'notifications': notifications,
      'reminderTime': reminderTime,
      'aiInsights': aiInsights,
      'language': language,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: ThemePreference.values.firstWhere(
        (t) => t.name == map['theme'],
        orElse: () => ThemePreference.system,
      ),
      notifications: map['notifications'] as bool? ?? true,
      reminderTime: map['reminderTime'] as String? ?? '20:00',
      aiInsights: map['aiInsights'] as bool? ?? true,
      language: map['language'] as String? ?? 'en',
    );
  }
}
