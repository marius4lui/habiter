import 'runtime_diagnostics.dart';
import 'runtime_feature_state.dart';

enum BackgroundRuntimeFailureKind { unsupported, malformedResponse, platform }

sealed class BackgroundRuntimeResult<T> {
  const BackgroundRuntimeResult();
}

final class BackgroundRuntimeSuccess<T> extends BackgroundRuntimeResult<T> {
  const BackgroundRuntimeSuccess(this.value);
  final T value;
}

final class BackgroundRuntimeFailure<T> extends BackgroundRuntimeResult<T> {
  const BackgroundRuntimeFailure(this.kind, this.safeMessage);
  final BackgroundRuntimeFailureKind kind;
  final String safeMessage;
}

final class BackgroundRuntimeSnapshot {
  const BackgroundRuntimeSnapshot({
    required this.features,
    required this.notificationsGranted,
    required this.batteryOptimized,
  });

  factory BackgroundRuntimeSnapshot.fromMap(Map<String, Object?> map) =>
      BackgroundRuntimeSnapshot(
        features: RuntimeFeatureState.fromMap(map),
        notificationsGranted: map['notificationsGranted'] as bool? ?? false,
        batteryOptimized: map['batteryOptimized'] as bool? ?? true,
      );

  final RuntimeFeatureState features;
  final bool notificationsGranted;
  final bool batteryOptimized;

  bool get backgroundReady => notificationsGranted && !batteryOptimized;
}

abstract interface class BackgroundRuntimeGateway {
  bool get isSupported;

  Future<BackgroundRuntimeResult<BackgroundRuntimeSnapshot>> snapshot();

  Future<BackgroundRuntimeResult<void>> reconcile({
    required RuntimeFeatureState features,
    required String reason,
  });

  Future<BackgroundRuntimeResult<void>> invalidateReminders();

  Future<BackgroundRuntimeResult<void>> openBatterySettings();

  Future<BackgroundRuntimeResult<RuntimeDiagnostics>> diagnostics();
}
