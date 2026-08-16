import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/data/key_value_habit_repository.dart';
import 'package:habiter/features/reminders/domain/reminder_policy.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes/in_memory_key_value_store.dart';
import '../../support/fakes/recording_notification_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('ordinary habit edits preserve a new reminder policy', () async {
    final store = InMemoryKeyValueStore();
    final provider = HabitProvider(
      repository: KeyValueHabitRepository(store),
      actionStore: store,
      notificationGateway: RecordingNotificationGateway(),
    );
    await provider.load();
    addTearDown(provider.dispose);
    final id = await provider.addHabit(
      name: 'Walk',
      category: 'Health',
      frequency: HabitFrequency.daily,
      targetCount: 1,
      color: '#467B68',
      icon: '🚶',
    );
    await provider.updateReminderPolicy(
      HabitReminderPolicy.smart(habitId: id, now: DateTime.now()),
    );

    await provider.updateHabit(
      id,
      provider.habits.single.copyWith(name: 'Evening walk'),
    );

    expect(provider.reminderPolicies[id]!.mode, ReminderMode.smart);
  });

  test('an explicit legacy time edit switches a Smart plan to fixed', () async {
    final store = InMemoryKeyValueStore();
    final provider = HabitProvider(
      repository: KeyValueHabitRepository(store),
      actionStore: store,
      notificationGateway: RecordingNotificationGateway(),
    );
    await provider.load();
    addTearDown(provider.dispose);
    final id = await provider.addHabit(
      name: 'Walk',
      category: 'Health',
      frequency: HabitFrequency.daily,
      targetCount: 1,
      color: '#467B68',
      icon: '🚶',
    );
    await provider.updateReminderPolicy(
      HabitReminderPolicy.smart(habitId: id, now: DateTime.now()),
    );

    await provider.updateHabit(
      id,
      provider.habits.single.copyWith(
        notificationEnabled: true,
        notificationTime: '11:15',
      ),
    );

    final policy = provider.reminderPolicies[id]!;
    expect(policy.mode, ReminderMode.fixedTimes);
    expect(policy.fixed!.times.single.toString(), '11:15');
  });
}
