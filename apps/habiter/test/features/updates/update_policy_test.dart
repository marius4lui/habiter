import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/domain/update_models.dart';
import 'package:habiter/features/updates/domain/update_policy.dart';
import 'package:habiter/features/updates/domain/update_state.dart';

import 'update_test_data.dart';

void main() {
  group('release selection', () {
    final manifest = manifestOf([
      releaseJson(build: 10600, channel: 'beta'),
      releaseJson(build: 10550, channel: 'stable'),
      releaseJson(build: 10500, channel: 'beta'),
    ]);
    const selector = UpdateSelector();

    test('Stable uses only the newest stable build', () {
      final result = selector.select(
        manifest: manifest,
        track: UpdateTrack.stable,
        currentBuild: 10400,
        platform: 'android',
        androidDistribution: AndroidDistribution.direct,
      );
      expect(result?.release.buildNumber, 10550);
      expect(result?.artifact.distribution, AndroidDistribution.direct);
    });

    test('Beta compares both channels and chooses the highest build', () {
      final result = selector.select(
        manifest: manifest,
        track: UpdateTrack.beta,
        currentBuild: 10400,
        platform: 'android',
        androidDistribution: AndroidDistribution.play,
      );
      expect(result?.release.buildNumber, 10600);
      expect(result?.artifact.distribution, AndroidDistribution.play);
    });

    test('switching from Beta to Stable never downgrades', () {
      final result = selector.select(
        manifest: manifest,
        track: UpdateTrack.stable,
        currentBuild: 10600,
        platform: 'android',
        androidDistribution: AndroidDistribution.direct,
      );
      expect(result, isNull);
    });

    test('aggregates every skipped build for the post-upgrade story', () {
      expect(
        selector
            .releasesBetween(
              manifest: manifest,
              previousBuild: 10400,
              currentBuild: 10600,
            )
            .map((release) => release.buildNumber),
        [10600, 10550, 10500],
      );
    });
  });

  group('update profiles', () {
    const policy = UpdatePolicy();
    final now = DateTime.utc(2026, 8, 17, 12);

    test('manual checks always bypass intervals', () {
      for (final profile in UpdateProfile.values) {
        expect(
          policy.shouldCheck(
            profile: profile,
            trigger: UpdateCheckTrigger.manual,
            now: now,
            lastCheckedAt: now,
          ),
          isTrue,
        );
      }
    });

    test('Immediate checks start/resume and hourly foreground ticks', () {
      expect(
        policy.shouldCheck(
          profile: UpdateProfile.immediate,
          trigger: UpdateCheckTrigger.resume,
          now: now,
          lastCheckedAt: now,
        ),
        isTrue,
      );
      expect(
        policy.shouldCheck(
          profile: UpdateProfile.immediate,
          trigger: UpdateCheckTrigger.foregroundTimer,
          now: now,
          lastCheckedAt: now.subtract(const Duration(minutes: 59)),
        ),
        isFalse,
      );
    });

    test('Balanced and Saver use 24-hour and seven-day intervals', () {
      expect(
        policy.shouldCheck(
          profile: UpdateProfile.balanced,
          trigger: UpdateCheckTrigger.startup,
          now: now,
          lastCheckedAt: now.subtract(const Duration(hours: 24)),
        ),
        isTrue,
      );
      expect(
        policy.shouldCheck(
          profile: UpdateProfile.saver,
          trigger: UpdateCheckTrigger.resume,
          now: now,
          lastCheckedAt: now.subtract(const Duration(days: 6)),
        ),
        isFalse,
      );
    });

    test('auto-download honors network cost', () {
      expect(
        policy.shouldAutoDownload(
          profile: UpdateProfile.immediate,
          isOnline: true,
          isMetered: true,
        ),
        isTrue,
      );
      expect(
        policy.shouldAutoDownload(
          profile: UpdateProfile.balanced,
          isOnline: true,
          isMetered: true,
        ),
        isFalse,
      );
      expect(
        policy.shouldAutoDownload(
          profile: UpdateProfile.saver,
          isOnline: true,
          isMetered: false,
        ),
        isFalse,
      );
    });
  });

  test('state machine rejects unsafe phase jumps', () {
    const state = UpdateState();
    final checking = state.transition(UpdatePhase.checking);
    expect(
      checking.transition(UpdatePhase.upToDate).phase,
      UpdatePhase.upToDate,
    );
    expect(() => state.transition(UpdatePhase.installing), throwsStateError);
  });
}
