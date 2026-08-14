import 'dart:collection';

import 'package:habiter/core/platform/platform_gateway.dart';

final class PlatformCall {
  PlatformCall(this.method, Map<String, Object?> arguments)
    : arguments = UnmodifiableMapView<String, Object?>(arguments);

  final String method;
  final Map<String, Object?> arguments;
}

final class RecordingPlatformGateway implements PlatformGateway {
  RecordingPlatformGateway({
    this.isSupported = true,
    Map<String, Object?> results = const <String, Object?>{},
  }) : _results = Map<String, Object?>.of(results);

  @override
  final bool isSupported;

  final Map<String, Object?> _results;
  final List<PlatformCall> calls = <PlatformCall>[];

  @override
  Future<T?> invoke<T>(
    String method, [
    Map<String, Object?> arguments = const <String, Object?>{},
  ]) async {
    calls.add(PlatformCall(method, arguments));
    final value = _results[method];
    if (value == null) return null;
    if (value is! T) {
      throw StateError(
        'Programmed result for $method is ${value.runtimeType}, not $T.',
      );
    }
    return value as T;
  }
}
