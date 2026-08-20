import 'dart:collection';

import '../../../models/habit.dart';

enum OnboardingStep {
  notStarted,
  welcome,
  intent,
  firstHabit,
  rhythm,
  rhythmExplainer,
  reminderModel,
  reminder,
  habitReady,
  widgetIntro,
  widgetPin,
  completed,
}

abstract final class OnboardingProgress {
  static const orderedSteps = <OnboardingStep>[
    OnboardingStep.welcome,
    OnboardingStep.intent,
    OnboardingStep.firstHabit,
    OnboardingStep.rhythm,
    OnboardingStep.rhythmExplainer,
    OnboardingStep.reminderModel,
    OnboardingStep.reminder,
    OnboardingStep.widgetIntro,
    OnboardingStep.widgetPin,
  ];

  static const total = 9;

  static int indexOf(OnboardingStep step) {
    final normalized = step == OnboardingStep.habitReady
        ? OnboardingStep.widgetIntro
        : step;
    final index = orderedSteps.indexOf(normalized);
    if (index >= 0) return index + 1;
    return normalized == OnboardingStep.completed ? total : 1;
  }

  static OnboardingStep previousOf(OnboardingStep step) {
    if (step == OnboardingStep.habitReady) return OnboardingStep.reminder;
    if (step == OnboardingStep.completed) return OnboardingStep.widgetPin;
    final index = orderedSteps.indexOf(step);
    if (index <= 0) return step;
    return orderedSteps[index - 1];
  }

  static List<OnboardingStep> through(OnboardingStep step) {
    final normalized = step == OnboardingStep.habitReady
        ? OnboardingStep.widgetIntro
        : step;
    final index = orderedSteps.indexOf(normalized);
    if (index < 0) return const <OnboardingStep>[OnboardingStep.welcome];
    return List<OnboardingStep>.unmodifiable(orderedSteps.take(index + 1));
  }
}

enum OnboardingIntent {
  health,
  fitness,
  mindfulness,
  learning,
  productivity,
  home,
  finance,
  other,
}

enum WidgetPromotionState { pending, presented, deferred, pinned, dismissed }

final class OnboardingHabitDraft {
  OnboardingHabitDraft({
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    required this.frequency,
    required this.targetCount,
    Iterable<int> customDays = const <int>[],
    this.templateId,
    this.reminderEnabled = false,
    this.reminderTime,
  }) : customDays = UnmodifiableListView<int>(
         (customDays.toSet().toList()..sort()),
       );

  factory OnboardingHabitDraft.fromMap(Map<String, Object?> map) =>
      OnboardingHabitDraft(
        name: map['name'] as String? ?? '',
        category: map['category'] as String? ?? 'Health',
        icon: map['icon'] as String? ?? '✓',
        color: map['color'] as String? ?? '#285943',
        frequency: HabitFrequency.values.byName(
          map['frequency'] as String? ?? HabitFrequency.daily.name,
        ),
        targetCount: (map['targetCount'] as num?)?.toInt() ?? 1,
        customDays: ((map['customDays'] as List<Object?>?) ?? const <Object?>[])
            .map((value) => (value as num).toInt()),
        templateId: map['templateId'] as String?,
        reminderEnabled: map['reminderEnabled'] as bool? ?? false,
        reminderTime: map['reminderTime'] as String?,
      );

  final String name;
  final String category;
  final String icon;
  final String color;
  final HabitFrequency frequency;
  final int targetCount;
  final List<int> customDays;
  final String? templateId;
  final bool reminderEnabled;
  final String? reminderTime;

  OnboardingHabitDraft copyWith({
    String? name,
    String? category,
    String? icon,
    String? color,
    HabitFrequency? frequency,
    int? targetCount,
    Iterable<int>? customDays,
    String? templateId,
    bool? reminderEnabled,
    String? reminderTime,
    bool clearReminderTime = false,
  }) => OnboardingHabitDraft(
    name: name ?? this.name,
    category: category ?? this.category,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    frequency: frequency ?? this.frequency,
    targetCount: targetCount ?? this.targetCount,
    customDays: customDays ?? this.customDays,
    templateId: templateId ?? this.templateId,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderTime: clearReminderTime ? null : reminderTime ?? this.reminderTime,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'name': name,
    'category': category,
    'icon': icon,
    'color': color,
    'frequency': frequency.name,
    'targetCount': targetCount,
    'customDays': customDays,
    'templateId': templateId,
    'reminderEnabled': reminderEnabled,
    'reminderTime': reminderTime,
  };
}

final class OnboardingState {
  const OnboardingState({
    this.onboardingVersion = currentVersion,
    this.currentStep = OnboardingStep.notStarted,
    this.intent,
    this.habitDraft,
    this.firstHabitId,
    this.widgetPromotionState = WidgetPromotionState.pending,
    this.widgetPinned = false,
    this.widgetPinAttempted = false,
    this.completedAt,
  });

  static const currentVersion = 3;

  factory OnboardingState.fromMap(Map<String, Object?> map) {
    final draft = map['habitDraft'];
    final storedVersion = (map['onboardingVersion'] as num?)?.toInt() ?? 1;
    if (storedVersion > currentVersion) {
      throw FormatException('Unsupported onboarding version: $storedVersion');
    }
    final storedStep = OnboardingStep.values.byName(
      map['currentStep'] as String? ?? OnboardingStep.notStarted.name,
    );
    return OnboardingState(
      onboardingVersion: currentVersion,
      currentStep: _migrateStep(storedVersion, storedStep),
      intent: map['intent'] == null
          ? null
          : OnboardingIntent.values.byName(map['intent']! as String),
      habitDraft: draft is Map
          ? OnboardingHabitDraft.fromMap(Map<String, Object?>.from(draft))
          : null,
      firstHabitId: map['firstHabitId'] as String?,
      widgetPromotionState: WidgetPromotionState.values.byName(
        map['widgetPromotionState'] as String? ??
            WidgetPromotionState.pending.name,
      ),
      widgetPinned: map['widgetPinned'] as bool? ?? false,
      widgetPinAttempted: map['widgetPinAttempted'] as bool? ?? false,
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.parse(map['completedAt']! as String),
    );
  }

  final int onboardingVersion;
  final OnboardingStep currentStep;
  final OnboardingIntent? intent;
  final OnboardingHabitDraft? habitDraft;
  final String? firstHabitId;
  final WidgetPromotionState widgetPromotionState;
  final bool widgetPinned;
  final bool widgetPinAttempted;
  final DateTime? completedAt;

  bool get isComplete => currentStep == OnboardingStep.completed;

  OnboardingState copyWith({
    int? onboardingVersion,
    OnboardingStep? currentStep,
    OnboardingIntent? intent,
    OnboardingHabitDraft? habitDraft,
    String? firstHabitId,
    WidgetPromotionState? widgetPromotionState,
    bool? widgetPinned,
    bool? widgetPinAttempted,
    DateTime? completedAt,
  }) => OnboardingState(
    onboardingVersion: onboardingVersion ?? this.onboardingVersion,
    currentStep: currentStep ?? this.currentStep,
    intent: intent ?? this.intent,
    habitDraft: habitDraft ?? this.habitDraft,
    firstHabitId: firstHabitId ?? this.firstHabitId,
    widgetPromotionState: widgetPromotionState ?? this.widgetPromotionState,
    widgetPinned: widgetPinned ?? this.widgetPinned,
    widgetPinAttempted: widgetPinAttempted ?? this.widgetPinAttempted,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'onboardingVersion': onboardingVersion,
    'currentStep': currentStep.name,
    'intent': intent?.name,
    'habitDraft': habitDraft?.toMap(),
    'firstHabitId': firstHabitId,
    'widgetPromotionState': widgetPromotionState.name,
    'widgetPinned': widgetPinned,
    'widgetPinAttempted': widgetPinAttempted,
    'completedAt': completedAt?.toUtc().toIso8601String(),
  };

  static OnboardingStep _migrateStep(
    int storedVersion,
    OnboardingStep storedStep,
  ) {
    if (storedVersion >= 3) return storedStep;
    return switch (storedStep) {
      OnboardingStep.reminder => OnboardingStep.rhythmExplainer,
      OnboardingStep.habitReady => OnboardingStep.widgetIntro,
      _ => storedStep,
    };
  }
}
