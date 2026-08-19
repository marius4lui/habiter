sealed class AppBlockRequirement {
  const AppBlockRequirement();

  Map<String, Object?> toMap();

  factory AppBlockRequirement.fromMap(Map<String, dynamic> map) =>
      switch (map['type']) {
        'habits' => HabitRequirement(
          ((map['habitIds'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>(),
        ),
        _ => const GeneralRequirement(),
      };
}

final class GeneralRequirement extends AppBlockRequirement {
  const GeneralRequirement();

  @override
  Map<String, Object?> toMap() => const <String, Object?>{'type': 'general'};

  @override
  bool operator ==(Object other) => other is GeneralRequirement;

  @override
  int get hashCode => 0x47454e;
}

final class HabitRequirement extends AppBlockRequirement {
  HabitRequirement(Iterable<String> habitIds)
    : habitIds = Set<String>.unmodifiable(
        habitIds.where((id) => id.isNotEmpty),
      );

  final Set<String> habitIds;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'type': 'habits',
    'habitIds': habitIds.toList()..sort(),
  };

  @override
  bool operator ==(Object other) =>
      other is HabitRequirement &&
      habitIds.length == other.habitIds.length &&
      habitIds.containsAll(other.habitIds);

  @override
  int get hashCode => Object.hashAll(habitIds.toList()..sort());
}

final class AppBlockRule {
  const AppBlockRule({
    required this.packageName,
    required this.appName,
    required this.requirement,
    this.enabled = true,
  });

  final String packageName;
  final String appName;
  final AppBlockRequirement requirement;
  final bool enabled;

  AppBlockRule copyWith({
    String? appName,
    AppBlockRequirement? requirement,
    bool? enabled,
  }) => AppBlockRule(
    packageName: packageName,
    appName: appName ?? this.appName,
    requirement: requirement ?? this.requirement,
    enabled: enabled ?? this.enabled,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'packageName': packageName,
    'appName': appName,
    'requirement': requirement.toMap(),
    'enabled': enabled,
  };

  factory AppBlockRule.fromMap(Map<String, dynamic> map) => AppBlockRule(
    packageName: map['packageName'] as String? ?? '',
    appName: map['appName'] as String? ?? map['packageName'] as String? ?? '',
    requirement: AppBlockRequirement.fromMap(
      Map<String, dynamic>.from(
        (map['requirement'] as Map?) ?? const <String, dynamic>{},
      ),
    ),
    enabled: map['enabled'] as bool? ?? true,
  );
}
