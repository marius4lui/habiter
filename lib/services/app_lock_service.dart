import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/locked_app.dart';

/// Service for communicating with Android native code for app lock functionality.
/// Only works on Android - iOS does not support blocking other apps.
class AppLockService {
  static const _channel = MethodChannel('com.habiter.app/applock');

  /// Check if the app is running on Android
  static bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  /// Get list of installed non-system apps
  static Future<List<LockedApp>> getInstalledApps() async {
    if (!isSupported) return [];

    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return [];

      return result.map((app) {
        final map = Map<String, dynamic>.from(app as Map);
        return LockedApp(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
          iconBytes: map['iconBytes'] != null
              ? Uint8List.fromList(List<int>.from(map['iconBytes'] as List))
              : null,
          isLocked: false,
        );
      }).toList();
    } on PlatformException catch (e) {
      debugPrint('Error getting installed apps: ${e.message}');
      return [];
    }
  }

  /// Check if usage stats permission is granted
  static Future<bool> hasUsageStatsPermission() async {
    if (!isSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking usage stats permission: ${e.message}');
      return false;
    }
  }

  /// Open system settings to grant usage stats permission
  static Future<void> requestUsageStatsPermission() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('requestUsageStatsPermission');
    } on PlatformException catch (e) {
      debugPrint('Error requesting usage stats permission: ${e.message}');
    }
  }

  /// Check if overlay permission is granted (needed to show blocking overlay)
  static Future<bool> hasOverlayPermission() async {
    if (!isSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking overlay permission: ${e.message}');
      return false;
    }
  }

  /// Open system settings to grant overlay permission
  static Future<void> requestOverlayPermission() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } on PlatformException catch (e) {
      debugPrint('Error requesting overlay permission: ${e.message}');
    }
  }

  /// Start the app monitoring service with list of locked package names
  static Future<bool> startMonitoring(List<String> lockedPackageNames) async {
    if (!isSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'startMonitoring',
        {'lockedPackages': lockedPackageNames},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error starting monitoring: ${e.message}');
      return false;
    }
  }

  /// Stop the app monitoring service
  static Future<void> stopMonitoring() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('stopMonitoring');
    } on PlatformException catch (e) {
      debugPrint('Error stopping monitoring: ${e.message}');
    }
  }

  /// Update the list of locked apps while monitoring is active
  static Future<void> updateLockedApps(List<String> lockedPackageNames) async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>(
        'updateLockedApps',
        {'lockedPackages': lockedPackageNames},
      );
    } on PlatformException catch (e) {
      debugPrint('Error updating locked apps: ${e.message}');
    }
  }

  /// Notify the native service that habits are complete (unlock apps)
  static Future<void> notifyHabitsComplete() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('habitsComplete');
    } on PlatformException catch (e) {
      debugPrint('Error notifying habits complete: ${e.message}');
    }
  }

  /// Notify the native service that habits are incomplete (lock apps again)
  static Future<void> notifyHabitsIncomplete() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('habitsIncomplete');
    } on PlatformException catch (e) {
      debugPrint('Error notifying habits incomplete: ${e.message}');
    }
  }

  /// Check if the app is battery optimized (bad for service reliability)
  static Future<bool> isBatteryOptimized() async {
    if (!isSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimized');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking battery optimization: ${e.message}');
      return false;
    }
  }

  /// Request exemption from battery optimization
  static Future<void> requestBatteryOptimizationExemption() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('requestBatteryOptimizationExemption');
    } on PlatformException catch (e) {
      debugPrint('Error requesting battery exemption: ${e.message}');
    }
  }

  /// Update the list of incomplete habit names for overlay display
  static Future<void> updateIncompleteHabits(List<String> habitNames) async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>(
        'updateIncompleteHabits',
        {'habitNames': habitNames},
      );
    } on PlatformException catch (e) {
      debugPrint('Error updating incomplete habits: ${e.message}');
    }
  }
}
