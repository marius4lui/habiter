import 'update_models.dart';

final class UpdateState {
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.candidate,
    this.progress = 0,
    this.errorCode,
    this.isOnline = true,
    this.lastCheckedAt,
  });

  final UpdatePhase phase;
  final UpdateCandidate? candidate;
  final double progress;
  final String? errorCode;
  final bool isOnline;
  final DateTime? lastCheckedAt;

  bool get hasUpdate => candidate != null;
  bool get isMandatory => phase == UpdatePhase.mandatory;

  UpdateState transition(
    UpdatePhase next, {
    UpdateCandidate? candidate,
    double? progress,
    String? errorCode,
    bool? isOnline,
    DateTime? lastCheckedAt,
  }) {
    if (!_allowed[phase]!.contains(next)) {
      throw StateError(
        'Invalid update transition: ${phase.name} -> ${next.name}',
      );
    }
    final nextProgress = progress ?? this.progress;
    if (nextProgress < 0 || nextProgress > 1) {
      throw RangeError.range(nextProgress, 0, 1, 'progress');
    }
    return UpdateState(
      phase: next,
      candidate: candidate ?? this.candidate,
      progress: nextProgress,
      errorCode: errorCode,
      isOnline: isOnline ?? this.isOnline,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  static const Map<UpdatePhase, Set<UpdatePhase>> _allowed = {
    UpdatePhase.idle: {UpdatePhase.checking, UpdatePhase.available},
    UpdatePhase.checking: {
      UpdatePhase.upToDate,
      UpdatePhase.available,
      UpdatePhase.mandatory,
      UpdatePhase.error,
    },
    UpdatePhase.upToDate: {UpdatePhase.checking, UpdatePhase.available},
    UpdatePhase.available: {
      UpdatePhase.checking,
      UpdatePhase.downloading,
      UpdatePhase.mandatory,
      UpdatePhase.error,
    },
    UpdatePhase.downloading: {
      UpdatePhase.downloading,
      UpdatePhase.verifying,
      UpdatePhase.available,
      UpdatePhase.mandatory,
      UpdatePhase.error,
    },
    UpdatePhase.verifying: {
      UpdatePhase.ready,
      UpdatePhase.restartRequired,
      UpdatePhase.available,
      UpdatePhase.error,
    },
    UpdatePhase.ready: {
      UpdatePhase.installing,
      UpdatePhase.checking,
      UpdatePhase.error,
    },
    UpdatePhase.restartRequired: {
      UpdatePhase.installing,
      UpdatePhase.checking,
      UpdatePhase.error,
    },
    UpdatePhase.installing: {
      UpdatePhase.ready,
      UpdatePhase.restartRequired,
      UpdatePhase.error,
    },
    UpdatePhase.mandatory: {
      UpdatePhase.downloading,
      UpdatePhase.ready,
      UpdatePhase.restartRequired,
      UpdatePhase.installing,
      UpdatePhase.checking,
      UpdatePhase.error,
    },
    UpdatePhase.unsupported: {},
    UpdatePhase.error: {
      UpdatePhase.checking,
      UpdatePhase.available,
      UpdatePhase.downloading,
    },
  };
}
