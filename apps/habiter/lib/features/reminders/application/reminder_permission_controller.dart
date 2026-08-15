enum ReminderPermissionStatus {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}

final class ReminderPermissionSnapshot {
  const ReminderPermissionSnapshot({
    required this.notifications,
    required this.exactAlarmAvailable,
  });

  final ReminderPermissionStatus notifications;
  final bool exactAlarmAvailable;
  bool get canSchedule => notifications == ReminderPermissionStatus.granted;
}

abstract interface class ReminderPermissionGateway {
  Future<ReminderPermissionSnapshot> current();

  Future<ReminderPermissionStatus> requestNotifications();

  Future<void> openSystemSettings();
}

final class ReminderPermissionController {
  ReminderPermissionController(this._gateway);

  final ReminderPermissionGateway _gateway;
  bool _promptedThisSession = false;
  ReminderPermissionSnapshot _state = const ReminderPermissionSnapshot(
    notifications: ReminderPermissionStatus.unknown,
    exactAlarmAvailable: false,
  );

  ReminderPermissionSnapshot get state => _state;

  Future<ReminderPermissionSnapshot> refresh() async {
    _state = await _gateway.current();
    return _state;
  }

  Future<ReminderPermissionSnapshot> requestAfterUserIntent() async {
    await refresh();
    if (_state.canSchedule ||
        _state.notifications == ReminderPermissionStatus.unsupported ||
        _state.notifications == ReminderPermissionStatus.permanentlyDenied ||
        _promptedThisSession) {
      return _state;
    }
    _promptedThisSession = true;
    final result = await _gateway.requestNotifications();
    _state = ReminderPermissionSnapshot(
      notifications: result,
      exactAlarmAvailable: _state.exactAlarmAvailable,
    );
    return _state;
  }

  Future<void> openSettings() => _gateway.openSystemSettings();
}
