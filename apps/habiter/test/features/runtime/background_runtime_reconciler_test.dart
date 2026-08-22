import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/runtime/application/background_runtime_reconciler.dart';
import 'package:habiter/features/runtime/domain/background_runtime_gateway.dart';
import 'package:habiter/features/runtime/domain/runtime_diagnostics.dart';
import 'package:habiter/features/runtime/domain/runtime_feature_state.dart';

void main() {
  test('disabling App Block preserves an active reminder runtime', () async {
    final gateway = _RuntimeGateway(
      const RuntimeFeatureState(remindersEnabled: true, appBlockEnabled: true),
    );

    await BackgroundRuntimeReconciler(gateway).setAppBlockEnabled(false);

    expect(gateway.features.remindersEnabled, isTrue);
    expect(gateway.features.appBlockEnabled, isFalse);
    expect(gateway.features.shouldRun, isTrue);
  });

  test('disabling reminders preserves an active App Block runtime', () async {
    final gateway = _RuntimeGateway(
      const RuntimeFeatureState(remindersEnabled: true, appBlockEnabled: true),
    );

    await BackgroundRuntimeReconciler(gateway).setRemindersEnabled(false);

    expect(gateway.features.remindersEnabled, isFalse);
    expect(gateway.features.appBlockEnabled, isTrue);
    expect(gateway.features.shouldRun, isTrue);
  });
}

final class _RuntimeGateway implements BackgroundRuntimeGateway {
  _RuntimeGateway(this.features);

  RuntimeFeatureState features;

  @override
  bool get isSupported => true;

  @override
  Future<BackgroundRuntimeResult<RuntimeDiagnostics>> diagnostics() async =>
      BackgroundRuntimeSuccess<RuntimeDiagnostics>(
        RuntimeDiagnostics(features: features),
      );

  @override
  Future<BackgroundRuntimeResult<void>> invalidateReminders() async =>
      const BackgroundRuntimeSuccess<void>(null);

  @override
  Future<BackgroundRuntimeResult<void>> openBatterySettings() async =>
      const BackgroundRuntimeSuccess<void>(null);

  @override
  Future<BackgroundRuntimeResult<void>> reconcile({
    required RuntimeFeatureState features,
    required String reason,
  }) async {
    this.features = features;
    return const BackgroundRuntimeSuccess<void>(null);
  }

  @override
  Future<BackgroundRuntimeResult<BackgroundRuntimeSnapshot>> snapshot() async =>
      BackgroundRuntimeSuccess<BackgroundRuntimeSnapshot>(
        BackgroundRuntimeSnapshot(
          features: features,
          notificationsGranted: true,
          batteryOptimized: false,
        ),
      );
}
