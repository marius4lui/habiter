import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/platform/notification_gateway.dart';
import '../core/time/local_date.dart';
import '../features/reminders/application/reminder_action_inbox.dart';
import '../features/reminders/application/reminder_diagnostics.dart';
import '../features/reminders/domain/reminder_action.dart';
import '../features/reminders/domain/reminder_payload.dart';
import '../features/reminders/infrastructure/device_time_zone_service.dart';

/// Callback for handling notification actions (marking habits complete)
typedef NotificationActionCallback =
    Future<void> Function(String habitId, String date);

/// Singleton service for managing local notifications
class NotificationService implements NotificationGateway {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationActionCallback? _onMarkComplete;

  // Notification channel IDs
  static const String _globalChannelId = 'habiter_global';
  static const String _globalChannelName = 'Tägliche Erinnerungen';
  static const String _globalChannelDesc =
      'Tägliche Erinnerungen für offene Habits';

  static const String _habitChannelId = 'habiter_habits';
  static const String _habitChannelName = 'Habit-Erinnerungen';
  static const String _habitChannelDesc =
      'Individuelle Erinnerungen für einzelne Habits';

  static const String _learningChannelId = 'habiter_learning';
  static const String _learningChannelName = 'Rhythmus lernen';
  static const String _learningChannelDesc =
      'Kurze Fragen zur Machbarkeit deiner Habits';

  static const String _requestLedgerKey = 'habiter_notification_requests_v1';

  bool _initialized = false;
  final DeviceTimeZoneService _timeZones = DeviceTimeZoneService(
    const MethodChannelDeviceTimeZoneGateway(),
  );

  /// Initialize the notification plugin and timezone data
  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Don't initialize on desktop platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint(
        'NotificationService: Skipping initialization on non-mobile platform',
      );
      _initialized = true;
      return;
    }

    // Initialize timezone
    tz.initializeTimeZones();
    await _timeZones.initialize();

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'habiter_reminder_actions',
          actions: [
            DarwinNotificationAction.plain('complete', 'Erledigt ✓'),
            DarwinNotificationAction.plain('snooze', 'Später'),
          ],
        ),
        DarwinNotificationCategory(
          'habiter_feedback_actions',
          actions: [
            DarwinNotificationAction.plain('feasibility_good', 'Jetzt gut'),
            DarwinNotificationAction.plain('feasibility_maybe', 'Vielleicht'),
            DarwinNotificationAction.plain('feasibility_bad', 'Gerade nicht'),
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
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
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
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Request notification permission (Android 13+)
      final notificationsGranted = await androidPlugin
          ?.requestNotificationsPermission();

      return notificationsGranted ?? false;
    }

    if (Platform.isIOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Refreshes the process-wide local timezone before reconciliation.
  Future<bool> refreshTimeZone() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    await initialize();
    return _timeZones.refreshIfChanged();
  }

  /// Check if notifications are permitted
  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }

    // iOS doesn't have a direct check, assume true if permissions were requested
    return true;
  }

  Future<AndroidScheduleMode> _getAndroidScheduleMode() async {
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> schedule(NotificationRequest request) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await initialize();
    final presentation = _presentationFor(request.category);
    final androidDetails = AndroidNotificationDetails(
      presentation.channelId,
      presentation.channelName,
      channelDescription: presentation.channelDescription,
      importance: request.category == NotificationCategory.overview
          ? Importance.high
          : Importance.defaultImportance,
      priority: request.category == NotificationCategory.overview
          ? Priority.high
          : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      actions: request.actions
          .map(
            (action) => AndroidNotificationAction(
              action.id,
              action.title,
              showsUserInterface: action.opensApp,
              cancelNotification: true,
            ),
          )
          .toList(growable: false),
    );
    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: presentation.iosCategory,
    );
    await _plugin.zonedSchedule(
      request.id,
      request.title,
      request.body,
      tz.TZDateTime.from(request.scheduledFor, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: request.payload['schema'] ?? jsonEncode(request.payload),
      androidScheduleMode: await _getAndroidScheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    await _upsertLedger(request);
  }

  @override
  Future<void> cancel(int id) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id);
    final ledger = await _loadLedger()
      ..remove(id);
    await _writeLedger(ledger);
  }

  @override
  Future<List<NotificationRequest>> pending() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const <NotificationRequest>[];
    }
    await initialize();
    final platformPending = await _plugin.pendingNotificationRequests();
    final ledger = await _loadLedger();
    final pendingIds = platformPending.map((item) => item.id).toSet();
    ledger.removeWhere((id, _) => !pendingIds.contains(id));
    await _writeLedger(ledger);
    return List<NotificationRequest>.unmodifiable(
      platformPending.map(
        (request) =>
            ledger[request.id] ??
            NotificationRequest(
              id: request.id,
              scheduledFor: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              title: request.title ?? 'Habiter reminder',
              body: request.body ?? '',
            ),
      ),
    );
  }

  _NotificationPresentation _presentationFor(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.calibration ||
        NotificationCategory.fineTuning => const _NotificationPresentation(
          channelId: _learningChannelId,
          channelName: _learningChannelName,
          channelDescription: _learningChannelDesc,
          iosCategory: 'habiter_feedback_actions',
        ),
        NotificationCategory.overview => const _NotificationPresentation(
          channelId: _globalChannelId,
          channelName: _globalChannelName,
          channelDescription: _globalChannelDesc,
          iosCategory: null,
        ),
        NotificationCategory.reminder => const _NotificationPresentation(
          channelId: _habitChannelId,
          channelName: _habitChannelName,
          channelDescription: _habitChannelDesc,
          iosCategory: 'habiter_reminder_actions',
        ),
      };

  Future<void> _upsertLedger(NotificationRequest request) async {
    final ledger = await _loadLedger();
    ledger[request.id] = request;
    await _writeLedger(ledger);
  }

  Future<Map<int, NotificationRequest>> _loadLedger() async {
    final preferences = SharedPreferencesAsync();
    final raw = await preferences.getString(_requestLedgerKey);
    if (raw == null) return <int, NotificationRequest>{};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return <int, NotificationRequest>{
        for (final value in decoded)
          if (value is Map)
            (value['id'] as num).toInt(): _requestFromMap(
              Map<String, Object?>.from(value),
            ),
      };
    } catch (_) {
      return <int, NotificationRequest>{};
    }
  }

  Future<void> _writeLedger(Map<int, NotificationRequest> ledger) async {
    final preferences = SharedPreferencesAsync();
    final values = ledger.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    await preferences.setString(
      _requestLedgerKey,
      jsonEncode(values.map(_requestToMap).toList(growable: false)),
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancelAll();
    await SharedPreferencesAsync().remove(_requestLedgerKey);
    debugPrint('NotificationService: Cancelled all notifications');
  }

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    const androidDetails = AndroidNotificationDetails(
      _globalChannelId,
      _globalChannelName,
      channelDescription: _globalChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      999,
      'Test Notification',
      'Notifications funktionieren! 🎉',
      details,
    );
  }

  Future<List<ReminderDiagnosticItem>> pendingDiagnostics() async {
    final requests = await pending();
    return List<ReminderDiagnosticItem>.unmodifiable(
      requests.map(
        (request) => ReminderDiagnosticItem(
          id: request.id,
          title: request.title,
          scheduledFor: request.scheduledFor,
        ),
      ),
    );
  }

  // Handle notification tap/action
  void _onNotificationResponse(NotificationResponse response) {
    unawaited(
      _persistNotificationResponse(response).then((record) {
        if (record?.kind == ReminderActionKind.complete &&
            _onMarkComplete != null) {
          return _onMarkComplete!(
            record!.habitId,
            record.occurrence.toString(),
          );
        }
      }),
    );
  }
}

// Background handler must be top-level
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await _persistNotificationResponse(response);
}

Future<ReminderActionRecord?> _persistNotificationResponse(
  NotificationResponse response,
) async {
  if (response.payload == null) return null;
  final kind = ReminderActionKind.fromPlatformId(response.actionId);
  if (kind == ReminderActionKind.open) return null;
  final payload = _decodeActionPayload(response.payload!);
  if (payload == null) return null;
  final preferences = SharedPreferencesAsync();
  final raw = await preferences.getString(ReminderActionInbox.storageKey);
  final records = raw == null
      ? <dynamic>[]
      : (jsonDecode(raw) as List<dynamic>);
  final id =
      '${response.id ?? 0}:${payload.stableNotificationKey}:${kind.platformId}';
  if (records.any((value) => (value as Map<dynamic, dynamic>)['id'] == id)) {
    return ReminderActionRecord.fromMap(
      Map<String, Object?>.from(
        records.firstWhere(
              (value) => (value as Map<dynamic, dynamic>)['id'] == id,
            )
            as Map,
      ),
    );
  }
  final record = ReminderActionRecord(
    id: id,
    habitId: payload.habitId,
    occurrence: payload.occurrence,
    receivedAt: DateTime.now().toUtc(),
    notificationKey: payload.stableNotificationKey,
    kind: kind,
    notificationKind: payload.kind,
    snoozeDuration: payload.snoozeDuration,
  );
  records.add(record.toMap());
  await preferences.setString(
    ReminderActionInbox.storageKey,
    jsonEncode(records),
  );
  return record;
}

ReminderPayload? _decodeActionPayload(String payload) {
  if (payload.startsWith('{')) {
    try {
      return ReminderPayload.fromMap(
        Map<String, Object?>.from(jsonDecode(payload) as Map<dynamic, dynamic>),
      );
    } on FormatException {
      return null;
    }
  }
  final parts = payload.split('|');
  if (parts.length != 2) return null;
  try {
    return ReminderPayload(
      habitId: parts[0],
      occurrence: LocalDate.parse(parts[1]),
    );
  } on FormatException {
    return null;
  }
}

final class _NotificationPresentation {
  const _NotificationPresentation({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.iosCategory,
  });

  final String channelId;
  final String channelName;
  final String channelDescription;
  final String? iosCategory;
}

Map<String, Object?> _requestToMap(NotificationRequest request) =>
    <String, Object?>{
      'id': request.id,
      'scheduledFor': request.scheduledFor.toUtc().toIso8601String(),
      'title': request.title,
      'body': request.body,
      'payload': request.payload,
      'category': request.category.name,
      'actions': request.actions
          .map(
            (action) => <String, Object?>{
              'id': action.id,
              'title': action.title,
              'opensApp': action.opensApp,
            },
          )
          .toList(growable: false),
    };

NotificationRequest _requestFromMap(Map<String, Object?> map) =>
    NotificationRequest(
      id: (map['id']! as num).toInt(),
      scheduledFor: DateTime.parse(map['scheduledFor']! as String),
      title: map['title']! as String,
      body: map['body']! as String,
      payload: Map<String, String>.from(map['payload']! as Map),
      category: NotificationCategory.values.byName(map['category']! as String),
      actions: ((map['actions'] as List<Object?>?) ?? const <Object?>[]).map((
        value,
      ) {
        final action = Map<String, Object?>.from(value! as Map);
        return NotificationActionSpec(
          id: action['id']! as String,
          title: action['title']! as String,
          opensApp: action['opensApp'] as bool? ?? false,
        );
      }),
    );
