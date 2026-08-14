import '../core/persistence/key_value_store.dart';
import '../core/persistence/legacy_storage_migrator.dart';
import '../core/persistence/shared_preferences_key_value_store.dart';
import '../core/time/clock.dart';
import '../core/ids/id_generator.dart';
import '../features/habits/application/habit_repository.dart';
import '../features/habits/data/key_value_habit_repository.dart';

typedef StartupTask = Future<void> Function();

final class AppDependencies {
  AppDependencies({
    required this.store,
    required this.clock,
    this.ids = const UuidIdGenerator(),
    required this.migrateStorage,
    required this.verifyRepository,
    required this.initializeOptionalServices,
    HabitRepository? habitRepository,
  }) : habitRepository = habitRepository ?? KeyValueHabitRepository(store);

  factory AppDependencies.production() {
    final store = SharedPreferencesKeyValueStore();
    const clock = SystemClock();
    final repository = KeyValueHabitRepository(store);
    return AppDependencies(
      store: store,
      clock: clock,
      habitRepository: repository,
      migrateStorage: () async {
        await migratorFor(store, clock).migrate();
      },
      verifyRepository: () async {
        await repository.load();
      },
      // Integrations are user-initiated. Keeping this task explicit prevents a
      // network or platform plugin from silently becoming a startup dependency.
      initializeOptionalServices: () async {},
    );
  }

  final KeyValueStore store;
  final Clock clock;
  final IdGenerator ids;
  final HabitRepository habitRepository;
  final StartupTask migrateStorage;
  final StartupTask verifyRepository;
  final StartupTask initializeOptionalServices;

  static LegacyStorageMigrator migratorFor(KeyValueStore store, Clock clock) =>
      LegacyStorageMigrator(store: store, clock: clock);
}
