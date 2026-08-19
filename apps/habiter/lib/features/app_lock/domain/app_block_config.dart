import 'dart:convert';

import '../../../models/locked_app.dart';
import 'app_block_rule.dart';

final class AppBlockConfig {
  const AppBlockConfig({
    this.isEnabled = false,
    this.rules = const <AppBlockRule>[],
    this.version = currentVersion,
  });

  static const currentVersion = 1;

  final bool isEnabled;
  final List<AppBlockRule> rules;
  final int version;

  List<AppBlockRule> get activeRules =>
      rules.where((rule) => rule.enabled).toList(growable: false);
  List<String> get lockedPackageNames =>
      activeRules.map((rule) => rule.packageName).toList(growable: false);

  // Compatibility views for the existing settings screen while it transitions
  // from one global requirement to per-app rules.
  List<LockedApp> get lockedApps => rules
      .map(
        (rule) => LockedApp(
          packageName: rule.packageName,
          appName: rule.appName,
          isLocked: rule.enabled,
        ),
      )
      .toList(growable: false);
  List<LockedApp> get activelyLockedApps =>
      lockedApps.where((app) => app.isLocked).toList(growable: false);
  bool get lockUntilAllHabitsComplete =>
      activeRules.every((rule) => rule.requirement is GeneralRequirement);
  List<String>? get requiredHabitIds {
    final requirements = activeRules
        .map((rule) => rule.requirement)
        .whereType<HabitRequirement>()
        .toList(growable: false);
    if (requirements.isEmpty) return null;
    return requirements.expand((value) => value.habitIds).toSet().toList()
      ..sort();
  }

  AppBlockConfig copyWith({bool? isEnabled, List<AppBlockRule>? rules}) =>
      AppBlockConfig(
        isEnabled: isEnabled ?? this.isEnabled,
        rules: List<AppBlockRule>.unmodifiable(rules ?? this.rules),
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'version': currentVersion,
    'isEnabled': isEnabled,
    'rules': rules.map((rule) => rule.toMap()).toList(growable: false),
  };

  factory AppBlockConfig.fromMap(Map<String, dynamic> map) {
    final rules = map['rules'];
    if (rules is List<dynamic>) {
      return AppBlockConfig(
        isEnabled: map['isEnabled'] as bool? ?? false,
        rules: rules
            .whereType<Map>()
            .map(
              (value) => AppBlockRule.fromMap(Map<String, dynamic>.from(value)),
            )
            .where((rule) => rule.packageName.isNotEmpty)
            .toList(growable: false),
      );
    }

    final legacyApps =
        ((map['lockedApps'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((value) => LockedApp.fromMap(Map<String, dynamic>.from(value)))
            .where((app) => app.isLocked);
    final allHabits = map['lockUntilAllHabitsComplete'] as bool? ?? true;
    final habitIds =
        ((map['requiredHabitIds'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<String>();
    final AppBlockRequirement requirement = allHabits
        ? const GeneralRequirement()
        : HabitRequirement(habitIds);
    return AppBlockConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      rules: legacyApps
          .map(
            (app) => AppBlockRule(
              packageName: app.packageName,
              appName: app.appName,
              requirement: requirement,
            ),
          )
          .toList(growable: false),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppBlockConfig.fromJson(String source) => AppBlockConfig.fromMap(
    Map<String, dynamic>.from(jsonDecode(source) as Map),
  );
}

typedef AppLockConfig = AppBlockConfig;
