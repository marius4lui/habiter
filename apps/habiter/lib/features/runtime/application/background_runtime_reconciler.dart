import '../domain/background_runtime_gateway.dart';
import '../domain/runtime_feature_state.dart';

final class BackgroundRuntimeReconciler {
  const BackgroundRuntimeReconciler(this._gateway);

  final BackgroundRuntimeGateway _gateway;

  Future<BackgroundRuntimeResult<void>> setRemindersEnabled(bool enabled) =>
      _update(
        reason: 'reminders_changed',
        transform: (state) => state.copyWith(remindersEnabled: enabled),
      );

  Future<BackgroundRuntimeResult<void>> setAppBlockEnabled(bool enabled) =>
      _update(
        reason: 'app_block_changed',
        transform: (state) => state.copyWith(appBlockEnabled: enabled),
      );

  Future<BackgroundRuntimeResult<void>> _update({
    required String reason,
    required RuntimeFeatureState Function(RuntimeFeatureState state) transform,
  }) async {
    final snapshot = await _gateway.snapshot();
    if (snapshot case BackgroundRuntimeFailure<BackgroundRuntimeSnapshot>(
      :final kind,
      :final safeMessage,
    )) {
      return BackgroundRuntimeFailure<void>(kind, safeMessage);
    }
    final current =
        (snapshot as BackgroundRuntimeSuccess<BackgroundRuntimeSnapshot>)
            .value
            .features;
    return _gateway.reconcile(features: transform(current), reason: reason);
  }
}
