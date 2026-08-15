import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/app/bootstrap.dart';
import 'package:habiter/app/dependencies.dart';
import 'package:habiter/core/persistence/storage_envelope.dart';
import 'package:habiter/core/time/clock.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';

import '../support/fakes/in_memory_key_value_store.dart';

void main() {
  test('migration completes before the repository is read', () async {
    final calls = <String>[];
    final store = InMemoryKeyValueStore(<String, Object?>{
      KeyValueHabitRepository.habitsKey: '[]',
      KeyValueHabitRepository.entriesKey: '[]',
    });
    final dependencies = AppDependencies(
      store: store,
      clock: const SystemClock(),
      migrateStorage: () async {
        calls.add('migrate');
        await AppDependencies.migratorFor(store, const SystemClock()).migrate();
      },
      verifyRepository: () async {
        expect(await store.contains(StorageEnvelope.storageKey), isTrue);
        calls.add('repository');
      },
      initializeOptionalServices: () async {
        calls.add('optional');
      },
    );

    final result = await AppBootstrap(dependencies).run();

    expect(result.isReady, isTrue);
    expect(calls, <String>['migrate', 'repository']);
  });

  test('startup failure is typed, redacted, and retryable', () async {
    var attempts = 0;
    final dependencies = AppDependencies(
      store: InMemoryKeyValueStore(),
      clock: const SystemClock(),
      migrateStorage: () async {
        attempts++;
        if (attempts == 1) {
          throw StateError('token=super-secret-value');
        }
      },
      verifyRepository: () async {},
      initializeOptionalServices: () async {},
    );
    final bootstrap = AppBootstrap(dependencies);

    final failed = await bootstrap.run();
    final recovered = await bootstrap.run();

    expect(failed.isReady, isFalse);
    expect(failed.failure?.phase, StartupPhase.migrateStorage);
    expect(failed.failure?.diagnostic, isNot(contains('super-secret-value')));
    expect(recovered.isReady, isTrue);
  });

  test('optional services are explicit and never part of cold start', () async {
    var optionalCalls = 0;
    final dependencies = AppDependencies(
      store: InMemoryKeyValueStore(),
      clock: const SystemClock(),
      migrateStorage: () async {},
      verifyRepository: () async {},
      initializeOptionalServices: () async => optionalCalls++,
    );

    final result = await AppBootstrap(dependencies).run();
    expect(optionalCalls, 0);

    await result.dependencies!.initializeOptionalServices();
    expect(optionalCalls, 1);
  });
}
