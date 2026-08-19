import '../domain/app_block_rule.dart';

enum AppBlockOnboardingStage {
  offer,
  reconsider,
  usageEducation,
  discovery,
  selection,
  binding,
  behaviorEducation,
  overlayEducation,
  review,
  completed,
  skipped,
  deferred,
}

enum AppBlockOnboardingResult { enabled, skipped, deferred }

final class AppBlockOnboardingState {
  const AppBlockOnboardingState({
    this.stage = AppBlockOnboardingStage.offer,
    this.selectedPackages = const <String>{},
    this.rules = const <AppBlockRule>[],
    this.usagePermissionSeen = false,
    this.overlayPermissionSeen = false,
    this.version = currentVersion,
  });

  static const currentVersion = 1;

  final AppBlockOnboardingStage stage;
  final Set<String> selectedPackages;
  final List<AppBlockRule> rules;
  final bool usagePermissionSeen;
  final bool overlayPermissionSeen;
  final int version;

  AppBlockOnboardingResult? get result => switch (stage) {
    AppBlockOnboardingStage.completed => AppBlockOnboardingResult.enabled,
    AppBlockOnboardingStage.skipped => AppBlockOnboardingResult.skipped,
    AppBlockOnboardingStage.deferred => AppBlockOnboardingResult.deferred,
    _ => null,
  };

  AppBlockOnboardingState copyWith({
    AppBlockOnboardingStage? stage,
    Set<String>? selectedPackages,
    List<AppBlockRule>? rules,
    bool? usagePermissionSeen,
    bool? overlayPermissionSeen,
  }) => AppBlockOnboardingState(
    stage: stage ?? this.stage,
    selectedPackages: Set<String>.unmodifiable(
      selectedPackages ?? this.selectedPackages,
    ),
    rules: List<AppBlockRule>.unmodifiable(rules ?? this.rules),
    usagePermissionSeen: usagePermissionSeen ?? this.usagePermissionSeen,
    overlayPermissionSeen: overlayPermissionSeen ?? this.overlayPermissionSeen,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'version': currentVersion,
    'stage': stage.name,
    'selectedPackages': selectedPackages.toList()..sort(),
    'rules': rules.map((rule) => rule.toMap()).toList(growable: false),
    'usagePermissionSeen': usagePermissionSeen,
    'overlayPermissionSeen': overlayPermissionSeen,
  };

  factory AppBlockOnboardingState.fromMap(Map<String, dynamic> map) =>
      AppBlockOnboardingState(
        stage: AppBlockOnboardingStage.values.firstWhere(
          (stage) => stage.name == map['stage'],
          orElse: () => AppBlockOnboardingStage.offer,
        ),
        selectedPackages:
            ((map['selectedPackages'] as List<dynamic>?) ?? const <dynamic>[])
                .whereType<String>()
                .toSet(),
        rules: ((map['rules'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (value) => AppBlockRule.fromMap(Map<String, dynamic>.from(value)),
            )
            .toList(growable: false),
        usagePermissionSeen: map['usagePermissionSeen'] as bool? ?? false,
        overlayPermissionSeen: map['overlayPermissionSeen'] as bool? ?? false,
      );
}
