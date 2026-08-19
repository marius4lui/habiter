import '../../../models/locked_app.dart';
import 'app_block_candidate.dart';
import 'app_block_projection.dart';

enum AppLockFailureKind {
  unsupported,
  permissionDenied,
  malformedResponse,
  platform,
}

sealed class AppLockResult<T> {
  const AppLockResult();
}

final class AppLockSuccess<T> extends AppLockResult<T> {
  const AppLockSuccess(this.value);
  final T value;
}

final class AppLockFailure<T> extends AppLockResult<T> {
  const AppLockFailure(this.kind, this.safeMessage);
  final AppLockFailureKind kind;
  final String safeMessage;
}

final class AppLockPermissionSnapshot {
  const AppLockPermissionSnapshot({
    required this.usageAccess,
    required this.overlay,
  });

  final bool usageAccess;
  final bool overlay;
  bool get ready => usageAccess && overlay;
}

abstract interface class AppLockGateway {
  bool get isSupported;

  Future<AppLockResult<List<LockedApp>>> installedApps();

  Future<AppLockResult<List<AppUsageRecord>>> recentUsage();

  Future<AppLockResult<AppLockPermissionSnapshot>> permissions();

  Future<AppLockResult<void>> requestUsageAccess();

  Future<AppLockResult<void>> requestOverlay();

  Future<AppLockResult<bool>> start(List<String> packageNames);

  Future<AppLockResult<void>> stop();

  Future<AppLockResult<void>> updatePackages(List<String> packageNames);

  Future<AppLockResult<void>> syncCompletion({
    required bool complete,
    required List<String> incompleteHabitNames,
  });

  Future<AppLockResult<void>> publishProjections(
    AppBlockProjectionSnapshot snapshot,
  );

  Future<AppLockResult<bool>> isBatteryOptimized();

  Future<AppLockResult<void>> openBatterySettings();
}
