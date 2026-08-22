import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/background_runtime_gateway.dart';
import '../domain/runtime_diagnostics.dart';
import '../domain/runtime_feature_state.dart';

final class MethodChannelBackgroundRuntimeGateway
    implements BackgroundRuntimeGateway {
  const MethodChannelBackgroundRuntimeGateway({
    MethodChannel channel = const MethodChannel('com.habiter.app/runtime'),
    bool? supported,
  }) : _channel = channel,
       _supported = supported;

  final MethodChannel _channel;
  final bool? _supported;

  @override
  bool get isSupported =>
      _supported ?? defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<BackgroundRuntimeResult<BackgroundRuntimeSnapshot>> snapshot() =>
      _map('getSnapshot', (map) => BackgroundRuntimeSnapshot.fromMap(map));

  @override
  Future<BackgroundRuntimeResult<void>> reconcile({
    required RuntimeFeatureState features,
    required String reason,
  }) => _void(
    'reconcile',
    arguments: <String, Object?>{...features.toMap(), 'reason': reason},
  );

  @override
  Future<BackgroundRuntimeResult<void>> invalidateReminders() =>
      _void('invalidateReminders');

  @override
  Future<BackgroundRuntimeResult<void>> openBatterySettings() =>
      _void('openBatterySettings');

  @override
  Future<BackgroundRuntimeResult<RuntimeDiagnostics>> diagnostics() =>
      _map('getDiagnostics', RuntimeDiagnostics.fromMap);

  Future<BackgroundRuntimeResult<T>> _map<T>(
    String method,
    T Function(Map<String, Object?> map) decode,
  ) => _invoke(
    method,
    decode: (value) => decode(Map<String, Object?>.from(value! as Map)),
  );

  Future<BackgroundRuntimeResult<void>> _void(
    String method, {
    Object? arguments,
  }) => _invoke(method, arguments: arguments, decode: (_) {});

  Future<BackgroundRuntimeResult<T>> _invoke<T>(
    String method, {
    Object? arguments,
    required T Function(Object? value) decode,
  }) async {
    if (!isSupported) {
      return BackgroundRuntimeFailure<T>(
        BackgroundRuntimeFailureKind.unsupported,
        'Background runtime is unavailable on this platform.',
      );
    }
    try {
      return BackgroundRuntimeSuccess<T>(
        decode(await _channel.invokeMethod<Object?>(method, arguments)),
      );
    } on TypeError {
      return BackgroundRuntimeFailure<T>(
        BackgroundRuntimeFailureKind.malformedResponse,
        'Background runtime returned an invalid response.',
      );
    } on PlatformException {
      return BackgroundRuntimeFailure<T>(
        BackgroundRuntimeFailureKind.platform,
        'Background runtime could not complete the platform request.',
      );
    } on MissingPluginException {
      return BackgroundRuntimeFailure<T>(
        BackgroundRuntimeFailureKind.unsupported,
        'Background runtime is unavailable on this platform.',
      );
    }
  }
}
