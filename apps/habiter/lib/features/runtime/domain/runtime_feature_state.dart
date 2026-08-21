enum RuntimeFeature { reminders, appBlock }

final class RuntimeFeatureState {
  const RuntimeFeatureState({
    required this.remindersEnabled,
    required this.appBlockEnabled,
  });

  factory RuntimeFeatureState.fromMap(Map<String, Object?> map) =>
      RuntimeFeatureState(
        remindersEnabled: map['remindersEnabled'] as bool? ?? false,
        appBlockEnabled: map['appBlockEnabled'] as bool? ?? false,
      );

  final bool remindersEnabled;
  final bool appBlockEnabled;

  bool get shouldRun => remindersEnabled || appBlockEnabled;

  Set<RuntimeFeature> get activeFeatures => <RuntimeFeature>{
    if (remindersEnabled) RuntimeFeature.reminders,
    if (appBlockEnabled) RuntimeFeature.appBlock,
  };

  Map<String, Object?> toMap() => <String, Object?>{
    'remindersEnabled': remindersEnabled,
    'appBlockEnabled': appBlockEnabled,
  };
}
