import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Callback for handling notification actions (marking habits complete)
typedef NotificationActionCallback = Future<void> Function(String habitId, String date);

/// Singleton service for managing local notifications
class NotificationService {
  NotificationService._();
  
  static final NotificationService instance = NotificationService._();
  
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  NotificationActionCallback? _onMarkComplete;
  
  // Notification channel IDs
  static const String _globalChannelId = 'habiter_global';
  static const String _globalChannelName = 'Tägliche Erinnerungen';
  static const String _globalChannelDesc = 'Tägliche Erinnerungen für offene Habits';
  
  static const String _habitChannelId = 'habiter_habits';
  static const String _habitChannelName = 'Habit-Erinnerungen';
  static const String _habitChannelDesc = 'Individuelle Erinnerungen für einzelne Habits';
  
  // Notification IDs
  static const int _globalNotificationId = 0;
  
  bool _initialized = false;
  
  /// Initialize the notification plugin and timezone data
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Don't initialize on desktop platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('NotificationService: Skipping initialization on non-mobile platform');
      _initialized = true;
      return;
    }
    
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'habiter_actions',
          actions: [
            DarwinNotificationAction.plain(
              'mark_complete',
              'Erledigt ✓',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );
    
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );
    
    _initialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }
  
  /// Set callback for when user marks habit complete via notification action
  void setActionCallback(NotificationActionCallback callback) {
    _onMarkComplete = callback;
  }
  
  /// Request notification permissions (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }
    
    if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return false;
  }
  
  /// Check if notifications are permitted
  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    
    // iOS doesn't have a direct check, assume true if permissions were requested
    return true;
  }
  
  /// Schedule the global daily reminder at the specified time
  Future<void> scheduleGlobalDailyReminder({
    required String time,
    required List<Habit> habits,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    // Cancel existing global notification
    await _plugin.cancel(_globalNotificationId);
    
    // Parse time string (HH:mm)
    final parts = time.split(':');
    if (parts.length != 2) return;
    
    final hour = int.tryParse(parts[0]) ?? 20;
    final minute = int.tryParse(parts[1]) ?? 0;
    
    // Calculate next occurrence
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Count incomplete habits for today
    final incompleteCount = habits.where((h) => h.isActive).length;
    
    final androidDetails = AndroidNotificationDetails(
      _globalChannelId,
      _globalChannelName,
      channelDescription: _globalChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'habiter_actions',
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _plugin.zonedSchedule(
      _globalNotificationId,
      'Habiter Erinnerung',
      'Du hast noch $incompleteCount Habits für heute offen!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
    
    debugPrint('NotificationService: Scheduled global reminder at $time');
  }
  
  /// Cancel the global daily reminder
  Future<void> cancelGlobalDailyReminder() async {
    await _plugin.cancel(_globalNotificationId);
    debugPrint('NotificationService: Cancelled global reminder');
  }
  
  /// Schedule a notification for a specific habit
  Future<void> scheduleHabitNotification(Habit habit) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!habit.notificationEnabled || habit.notificationTime == null) return;
    
    // Cancel existing notification for this habit
    await cancelHabitNotification(habit.id);
    
    // Parse time string (HH:mm)
    final parts = habit.notificationTime!.split(':');
    if (parts.length != 2) return;
    
    final hour = int.tryParse(parts[0]) ?? 20;
    final minute = int.tryParse(parts[1]) ?? 0;
    
    // Calculate next occurrence
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Generate unique ID from habit ID hash
    final notificationId = habit.id.hashCode.abs() % 100000 + 1; // Avoid 0 (global)
    
    final androidDetails = AndroidNotificationDetails(
      _habitChannelId,
      _habitChannelName,
      channelDescription: _habitChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          'mark_complete',
          'Erledigt ✓',
          showsUserInterface: true,
        ),
      ],
    );
    
    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'habiter_actions',
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    // Payload format: habitId|date
    final today = DateTime.now();
    final payload = '${habit.id}|${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    await _plugin.zonedSchedule(
      notificationId,
      habit.icon.isNotEmpty ? '${habit.icon} ${habit.name}' : habit.name,
      'Zeit für dein Habit! Tippe um als erledigt zu markieren.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: payload,
    );
    
    debugPrint('NotificationService: Scheduled habit notification for ${habit.name} at ${habit.notificationTime}');
  }
  
  /// Cancel notification for a specific habit
  Future<void> cancelHabitNotification(String habitId) async {
    final notificationId = habitId.hashCode.abs() % 100000 + 1;
    await _plugin.cancel(notificationId);
    debugPrint('NotificationService: Cancelled notification for habit $habitId');
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }
  
  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    final androidDetails = AndroidNotificationDetails(
      _globalChannelId,
      _globalChannelName,
      channelDescription: _globalChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final details = NotificationDetails(android: androidDetails);
    
    await _plugin.show(
      999,
      'Test Notification',
      'Notifications funktionieren! 🎉',
      details,
    );
  }
  
  // Handle notification tap/action
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('NotificationService: Response received: ${response.actionId}, payload: ${response.payload}');
    
    if (response.actionId == 'mark_complete' && response.payload != null) {
      _handleMarkComplete(response.payload!);
    }
  }
  
  void _handleMarkComplete(String payload) {
    // Payload format: habitId|date
    final parts = payload.split('|');
    if (parts.length != 2) return;
    
    final habitId = parts[0];
    final date = parts[1];
    
    if (_onMarkComplete != null) {
      _onMarkComplete!(habitId, date);
    }
  }
}

// Background handler must be top-level
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint('NotificationService: Background response: ${response.actionId}');
  // Background handling would require isolate communication
  // For now, we rely on foreground handling
}
