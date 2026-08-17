import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/data/update_local_repository.dart';
import 'package:habiter/features/updates/domain/update_models.dart';

import '../../support/fakes/in_memory_key_value_store.dart';

void main() {
  test(
    'update settings, cache and lifecycle markers survive a restart',
    () async {
      final store = InMemoryKeyValueStore();
      final repository = UpdateLocalRepository(store);
      final state = UpdateLocalState(
        track: UpdateTrack.beta,
        profile: UpdateProfile.immediate,
        cachedEnvelope: '{"signed":true}',
        etag: '"manifest"',
        lastCheckedAt: DateTime.utc(2026, 8, 17),
        presentedBuilds: const {10500},
        readyNotifiedBuilds: const {10500},
        downloadId: 'download-1',
        downloadBuild: 10500,
        previousAppBuild: 10402,
      );
      await repository.save(state);

      final restored = await repository.load();
      expect(restored.track, UpdateTrack.beta);
      expect(restored.profile, UpdateProfile.immediate);
      expect(restored.cachedEnvelope, state.cachedEnvelope);
      expect(restored.etag, state.etag);
      expect(restored.presentedBuilds, {10500});
      expect(restored.readyNotifiedBuilds, {10500});
      expect(restored.downloadId, 'download-1');
      expect(restored.previousAppBuild, 10402);
      expect(restored.metadataBytes, greaterThan(0));
    },
  );

  test('invalid persisted data fails safely to defaults', () async {
    final store = InMemoryKeyValueStore({
      UpdateLocalRepository.storageKey: '{broken',
    });
    final restored = await UpdateLocalRepository(store).load();
    expect(restored.track, UpdateTrack.stable);
    expect(restored.profile, UpdateProfile.balanced);
    expect(restored.cachedEnvelope, isNull);
  });
}
