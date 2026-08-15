import 'dart:io';

import 'package:flutter/services.dart';

import '../../../services/notification_service.dart';
import '../application/reminder_permission_controller.dart';

final class LocalReminderPermissionGateway
    implements ReminderPermissionGateway {
  const LocalReminderPermissionGateway({
    MethodChannel settingsChannel = const MethodChannel(
      'com.habiter.app/settings',
    ),
  }) : _settingsChannel = settingsChannel;

  final MethodChannel _settingsChannel;

  @override
  Future<ReminderPermissionSnapshot> current() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const ReminderPermissionSnapshot(
        notifications: ReminderPermissionStatus.unsupported,
        exactAlarmAvailable: false,
      );
    }
    final granted = await NotificationService.instance
        .areNotificationsEnabled();
    return ReminderPermissionSnapshot(
      notifications: granted
          ? ReminderPermissionStatus.granted
          : ReminderPermissionStatus.denied,
      // Habiter deliberately uses inexact scheduling by default.
      exactAlarmAvailable: false,
    );
  }

  @override
  Future<ReminderPermissionStatus> requestNotifications() async =>
      await NotificationService.instance.requestPermissions()
      ? ReminderPermissionStatus.granted
      : ReminderPermissionStatus.denied;

  @override
  Future<void> openSystemSettings() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _settingsChannel.invokeMethod<void>('openNotificationSettings');
    }
  }
}
