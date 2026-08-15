import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/time/local_date.dart';

abstract interface class DeviceTimeZoneGateway {
  Future<String?> currentTimeZoneId();
}

final class MethodChannelDeviceTimeZoneGateway
    implements DeviceTimeZoneGateway {
  const MethodChannelDeviceTimeZoneGateway({
    MethodChannel channel = const MethodChannel('com.habiter.app/timezone'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<String?> currentTimeZoneId() =>
      _channel.invokeMethod<String>('getTimeZoneId');
}

final class DeviceTimeZoneResolution {
  const DeviceTimeZoneResolution({
    required this.requestedId,
    required this.location,
    required this.usedFallback,
  });

  final String? requestedId;
  final tz.Location location;
  final bool usedFallback;
}

final class DeviceTimeZoneService {
  DeviceTimeZoneService(this._gateway);

  final DeviceTimeZoneGateway _gateway;
  String? _lastRequestedId;

  Future<DeviceTimeZoneResolution> initialize() async {
    tz_data.initializeTimeZones();
    String? requested;
    try {
      requested = await _gateway.currentTimeZoneId();
    } on PlatformException {
      requested = null;
    }
    final location = _locationOrUtc(requested);
    tz.setLocalLocation(location);
    _lastRequestedId = requested;
    return DeviceTimeZoneResolution(
      requestedId: requested,
      location: location,
      usedFallback: requested == null || location.name == 'UTC',
    );
  }

  Future<bool> refreshIfChanged() async {
    final requested = await _gateway.currentTimeZoneId();
    if (requested == _lastRequestedId) return false;
    final location = _locationOrUtc(requested);
    tz.setLocalLocation(location);
    _lastRequestedId = requested;
    return true;
  }

  static tz.TZDateTime resolveWallClock({
    required tz.Location location,
    required LocalDate date,
    required int hour,
    required int minute,
  }) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Invalid local reminder time.');
    }
    return tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  static tz.Location _locationOrUtc(String? id) {
    if (id == null || id.trim().isEmpty) return tz.UTC;
    try {
      return tz.getLocation(id);
    } on tz.LocationNotFoundException {
      return tz.UTC;
    }
  }
}
