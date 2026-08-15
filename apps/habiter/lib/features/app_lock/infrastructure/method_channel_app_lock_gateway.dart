import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../models/locked_app.dart';
import '../domain/app_lock_gateway.dart';

final class MethodChannelAppLockGateway implements AppLockGateway {
  const MethodChannelAppLockGateway({
    MethodChannel channel = const MethodChannel('com.habiter.app/applock'),
    bool? supported,
  }) : _channel = channel,
       _supported = supported;

  final MethodChannel _channel;
  final bool? _supported;

  @override
  bool get isSupported =>
      _supported ?? defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<AppLockResult<List<LockedApp>>> installedApps() => _invoke(
    'getInstalledApps',
    decode: (value) {
      final list = value as List<dynamic>? ?? const <dynamic>[];
      return list
          .map((item) {
            final map = Map<String, dynamic>.from(
              item as Map<dynamic, dynamic>,
            );
            return LockedApp(
              packageName: map['packageName']! as String,
              appName: map['appName']! as String,
              iconBytes: map['iconBytes'] == null
                  ? null
                  : Uint8List.fromList(
                      List<int>.from(map['iconBytes'] as List),
                    ),
            );
          })
          .toList(growable: false);
    },
  );

  @override
  Future<AppLockResult<AppLockPermissionSnapshot>> permissions() async {
    final usage = await _invoke<bool>(
      'hasUsageStatsPermission',
      decode: (value) => value as bool? ?? false,
    );
    if (usage is AppLockFailure<bool>) {
      return AppLockFailure<AppLockPermissionSnapshot>(
        usage.kind,
        usage.safeMessage,
      );
    }
    final overlay = await _invoke<bool>(
      'hasOverlayPermission',
      decode: (value) => value as bool? ?? false,
    );
    if (overlay is AppLockFailure<bool>) {
      return AppLockFailure<AppLockPermissionSnapshot>(
        overlay.kind,
        overlay.safeMessage,
      );
    }
    return AppLockSuccess<AppLockPermissionSnapshot>(
      AppLockPermissionSnapshot(
        usageAccess: (usage as AppLockSuccess<bool>).value,
        overlay: (overlay as AppLockSuccess<bool>).value,
      ),
    );
  }

  @override
  Future<AppLockResult<void>> requestUsageAccess() =>
      _void('requestUsageStatsPermission');

  @override
  Future<AppLockResult<void>> requestOverlay() =>
      _void('requestOverlayPermission');

  @override
  Future<AppLockResult<bool>> start(List<String> packageNames) => _invoke(
    'startMonitoring',
    arguments: <String, Object?>{'lockedPackages': packageNames},
    decode: (value) => value as bool? ?? false,
  );

  @override
  Future<AppLockResult<void>> stop() => _void('stopMonitoring');

  @override
  Future<AppLockResult<void>> updatePackages(List<String> packageNames) =>
      _void(
        'updateLockedApps',
        arguments: <String, Object?>{'lockedPackages': packageNames},
      );

  @override
  Future<AppLockResult<void>> syncCompletion({
    required bool complete,
    required List<String> incompleteHabitNames,
  }) async {
    final names = await _void(
      'updateIncompleteHabits',
      arguments: <String, Object?>{'habitNames': incompleteHabitNames},
    );
    if (names is AppLockFailure<void>) return names;
    return _void(complete ? 'habitsComplete' : 'habitsIncomplete');
  }

  @override
  Future<AppLockResult<bool>> isBatteryOptimized() =>
      _invoke('isBatteryOptimized', decode: (value) => value as bool? ?? false);

  @override
  Future<AppLockResult<void>> openBatterySettings() =>
      _void('requestBatteryOptimizationExemption');

  Future<AppLockResult<void>> _void(String method, {Object? arguments}) =>
      _invoke(method, arguments: arguments, decode: (_) {});

  Future<AppLockResult<T>> _invoke<T>(
    String method, {
    Object? arguments,
    required T Function(Object? value) decode,
  }) async {
    if (!isSupported) {
      return AppLockFailure<T>(
        AppLockFailureKind.unsupported,
        'App Lock is not supported on this platform.',
      );
    }
    try {
      return AppLockSuccess<T>(
        decode(await _channel.invokeMethod<Object?>(method, arguments)),
      );
    } on TypeError {
      return AppLockFailure<T>(
        AppLockFailureKind.malformedResponse,
        'App Lock returned an invalid response.',
      );
    } on PlatformException {
      return AppLockFailure<T>(
        AppLockFailureKind.platform,
        'App Lock could not complete the platform request.',
      );
    } on MissingPluginException {
      return AppLockFailure<T>(
        AppLockFailureKind.unsupported,
        'App Lock is unavailable on this platform.',
      );
    }
  }
}
