import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class HapticGateway {
  Future<void> selection();

  Future<void> success();
}

bool supportsHaptics(TargetPlatform platform, {required bool isWeb}) =>
    !isWeb &&
    (platform == TargetPlatform.android || platform == TargetPlatform.iOS);

final class SystemHapticGateway implements HapticGateway {
  const SystemHapticGateway({TargetPlatform? platform, bool? isWeb})
    : _platform = platform,
      _isWeb = isWeb;

  final TargetPlatform? _platform;
  final bool? _isWeb;

  bool get _supported => supportsHaptics(
    _platform ?? defaultTargetPlatform,
    isWeb: _isWeb ?? kIsWeb,
  );

  @override
  Future<void> selection() async {
    if (_supported) await HapticFeedback.selectionClick();
  }

  @override
  Future<void> success() async {
    if (_supported) await HapticFeedback.mediumImpact();
  }
}
