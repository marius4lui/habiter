import 'dart:convert';
import 'dart:typed_data';

/// Represents an app that can be locked until habits are completed
class LockedApp {
  const LockedApp({
    required this.packageName,
    required this.appName,
    this.iconBytes,
    this.isLocked = false,
  });

  /// Android package name (e.g., com.instagram.android)
  final String packageName;

  /// User-visible app name
  final String appName;

  /// App icon as bytes (from Android PackageManager)
  final Uint8List? iconBytes;

  /// Whether this app is currently locked
  final bool isLocked;

  LockedApp copyWith({
    String? packageName,
    String? appName,
    Uint8List? iconBytes,
    bool? isLocked,
  }) {
    return LockedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconBytes: iconBytes ?? this.iconBytes,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconBytes': iconBytes != null ? base64Encode(iconBytes!) : null,
      'isLocked': isLocked,
    };
  }

  factory LockedApp.fromMap(Map<String, dynamic> map) {
    return LockedApp(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBytes: map['iconBytes'] != null
          ? base64Decode(map['iconBytes'] as String)
          : null,
      isLocked: map['isLocked'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LockedApp.fromJson(String source) =>
      LockedApp.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LockedApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}

/// Configuration for the app lock feature
class AppLockConfig {
  const AppLockConfig({
    this.isEnabled = false,
    this.lockedApps = const [],
    this.lockUntilAllHabitsComplete = true,
    this.requiredHabitIds,
  });

  /// Whether the app lock feature is enabled
  final bool isEnabled;

  /// List of apps that are locked
  final List<LockedApp> lockedApps;

  /// If true, all habits must be completed to unlock
  /// If false, only habits in requiredHabitIds must be completed
  final bool lockUntilAllHabitsComplete;

  /// Specific habit IDs that must be completed to unlock (if lockUntilAllHabitsComplete is false)
  final List<String>? requiredHabitIds;

  /// Get only the apps that are marked as locked
  List<LockedApp> get activelyLockedApps =>
      lockedApps.where((app) => app.isLocked).toList();

  /// Get package names of locked apps
  List<String> get lockedPackageNames =>
      activelyLockedApps.map((app) => app.packageName).toList();

  AppLockConfig copyWith({
    bool? isEnabled,
    List<LockedApp>? lockedApps,
    bool? lockUntilAllHabitsComplete,
    List<String>? requiredHabitIds,
  }) {
    return AppLockConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      lockedApps: lockedApps ?? this.lockedApps,
      lockUntilAllHabitsComplete:
          lockUntilAllHabitsComplete ?? this.lockUntilAllHabitsComplete,
      requiredHabitIds: requiredHabitIds ?? this.requiredHabitIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'lockedApps': lockedApps.map((app) => app.toMap()).toList(),
      'lockUntilAllHabitsComplete': lockUntilAllHabitsComplete,
      'requiredHabitIds': requiredHabitIds,
    };
  }

  factory AppLockConfig.fromMap(Map<String, dynamic> map) {
    return AppLockConfig(
      isEnabled: map['isEnabled'] as bool? ?? false,
      lockedApps: (map['lockedApps'] as List<dynamic>?)
              ?.map((e) => LockedApp.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      lockUntilAllHabitsComplete:
          map['lockUntilAllHabitsComplete'] as bool? ?? true,
      requiredHabitIds: (map['requiredHabitIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppLockConfig.fromJson(String source) =>
      AppLockConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
