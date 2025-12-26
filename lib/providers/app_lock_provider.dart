import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/habit.dart';
import '../models/locked_app.dart';
import '../services/app_lock_service.dart';
import '../services/storage_service.dart';

/// Provider for managing app lock state and logic
class AppLockProvider extends ChangeNotifier {
  AppLockProvider();

  AppLockConfig _config = const AppLockConfig();
  List<LockedApp> _availableApps = [];
  bool _isLoading = false;
  String? _error;
  bool _hasUsageStatsPermission = false;
  bool _hasOverlayPermission = false;

  // Getters
  AppLockConfig get config => _config;
  List<LockedApp> get availableApps => _availableApps;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEnabled => _config.isEnabled;
  bool get hasUsageStatsPermission => _hasUsageStatsPermission;
  bool get hasOverlayPermission => _hasOverlayPermission;
  bool get hasAllPermissions => _hasUsageStatsPermission && _hasOverlayPermission;
  bool get isSupported => AppLockService.isSupported;

  /// Load saved config and check permissions
  Future<void> load() async {
    if (!isSupported) return;

    _isLoading = true;
    notifyListeners();

    try {
      _config = await StorageService.getAppLockConfig();
      await checkPermissions();
      _error = null;
    } catch (e) {
      _error = 'Failed to load app lock config';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if required permissions are granted
  Future<void> checkPermissions() async {
    if (!isSupported) return;

    _hasUsageStatsPermission = await AppLockService.hasUsageStatsPermission();
    _hasOverlayPermission = await AppLockService.hasOverlayPermission();
    notifyListeners();
  }

  /// Request usage stats permission
  Future<void> requestUsageStatsPermission() async {
    await AppLockService.requestUsageStatsPermission();
  }

  /// Request overlay permission
  Future<void> requestOverlayPermission() async {
    await AppLockService.requestOverlayPermission();
  }

  /// Load list of installed non-system apps
  Future<void> loadInstalledApps() async {
    if (!isSupported) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apps = await AppLockService.getInstalledApps();
      
      // Merge with saved locked apps to preserve isLocked state
      final lockedPackages = _config.lockedApps
          .where((a) => a.isLocked)
          .map((a) => a.packageName)
          .toSet();
      
      _availableApps = apps.map((app) {
        return app.copyWith(isLocked: lockedPackages.contains(app.packageName));
      }).toList();
      
      // Sort: locked apps first, then alphabetically
      _availableApps.sort((a, b) {
        if (a.isLocked && !b.isLocked) return -1;
        if (!a.isLocked && b.isLocked) return 1;
        return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
      });
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load installed apps';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle lock status for an app
  Future<void> toggleAppLock(String packageName) async {
    final index = _availableApps.indexWhere((a) => a.packageName == packageName);
    if (index == -1) return;

    final app = _availableApps[index];
    _availableApps[index] = app.copyWith(isLocked: !app.isLocked);

    // Update config
    _config = _config.copyWith(lockedApps: _availableApps);
    await _saveAndSync();
    notifyListeners();
  }

  /// Enable or disable app lock feature
  Future<void> setEnabled(bool enabled) async {
    _config = _config.copyWith(isEnabled: enabled);
    await _saveAndSync();
    notifyListeners();
  }

  /// Set whether all habits must be complete or specific ones
  Future<void> setLockUntilAllHabitsComplete(bool value) async {
    _config = _config.copyWith(lockUntilAllHabitsComplete: value);
    await _saveAndSync();
    notifyListeners();
  }

  /// Set specific habit IDs that must be completed
  Future<void> setRequiredHabitIds(List<String>? habitIds) async {
    _config = _config.copyWith(requiredHabitIds: habitIds);
    await _saveAndSync();
    notifyListeners();
  }

  /// Save config and sync with native service
  Future<void> _saveAndSync() async {
    await StorageService.saveAppLockConfig(_config);

    if (_config.isEnabled && _config.lockedPackageNames.isNotEmpty) {
      await AppLockService.startMonitoring(_config.lockedPackageNames);
    } else {
      await AppLockService.stopMonitoring();
    }
  }

  /// Check if habits requirement is met and update lock status
  Future<void> updateHabitCompletion({
    required List<Habit> habits,
    required List<HabitEntry> entries,
  }) async {
    if (!_config.isEnabled) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Get list of incomplete habits
    List<String> incompleteHabitNames = [];
    
    bool habitsComplete;
    if (_config.lockUntilAllHabitsComplete) {
      // Check all active habits
      final activeHabits = habits.where((h) => h.isActive).toList();
      for (final habit in activeHabits) {
        final isComplete = entries.any((e) => 
          e.habitId == habit.id && 
          e.date == today && 
          e.completed
        );
        if (!isComplete) {
          incompleteHabitNames.add(habit.name);
        }
      }
      habitsComplete = incompleteHabitNames.isEmpty;
    } else {
      // Check specific required habits
      final requiredIds = _config.requiredHabitIds ?? [];
      if (requiredIds.isEmpty) {
        habitsComplete = true;
      } else {
        for (final habitId in requiredIds) {
          final habit = habits.where((h) => h.id == habitId).firstOrNull;
          if (habit == null) continue;
          
          final isComplete = entries.any((e) =>
            e.habitId == habitId &&
            e.date == today &&
            e.completed
          );
          if (!isComplete) {
            incompleteHabitNames.add(habit.name);
          }
        }
        habitsComplete = incompleteHabitNames.isEmpty;
      }
    }

    // Update incomplete habits for overlay display
    await AppLockService.updateIncompleteHabits(incompleteHabitNames);

    // Notify native service
    if (habitsComplete) {
      await AppLockService.notifyHabitsComplete();
    } else {
      await AppLockService.notifyHabitsIncomplete();
    }
  }
}
