import 'dependencies.dart';

enum StartupPhase { migrateStorage, verifyRepository }

final class StartupFailure {
  const StartupFailure({required this.phase, required this.diagnostic});

  final StartupPhase phase;
  final String diagnostic;
}

final class BootstrapResult {
  const BootstrapResult._({this.dependencies, this.failure});

  factory BootstrapResult.ready(AppDependencies dependencies) =>
      BootstrapResult._(dependencies: dependencies);

  factory BootstrapResult.failed(StartupFailure failure) =>
      BootstrapResult._(failure: failure);

  final AppDependencies? dependencies;
  final StartupFailure? failure;

  bool get isReady => dependencies != null;
}

final class AppBootstrap {
  const AppBootstrap(this._dependencies);

  final AppDependencies _dependencies;

  AppDependencies get dependencies => _dependencies;

  Future<BootstrapResult> run() async {
    try {
      await _dependencies.migrateStorage();
    } catch (_) {
      return BootstrapResult.failed(
        const StartupFailure(
          phase: StartupPhase.migrateStorage,
          diagnostic: 'Local data preparation failed.',
        ),
      );
    }

    try {
      await _dependencies.verifyRepository();
    } catch (_) {
      return BootstrapResult.failed(
        const StartupFailure(
          phase: StartupPhase.verifyRepository,
          diagnostic: 'Local data verification failed.',
        ),
      );
    }

    return BootstrapResult.ready(_dependencies);
  }
}
