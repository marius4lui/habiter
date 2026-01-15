import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/providers/habit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('HabitProvider Tests', () {
    test('addHabit adds to the TOP of the list', () async {
      final provider = HabitProvider();

      // Simulate loading with empty data first (mock logic runs here but we manually override for test speed or just ignore)
      // Actually, since we need to test the "empty -> mock" logic, let's test that first.

      // We can't easily mock StorageService static methods without a wrapper or more complex setup.
      // However, we can test the `addHabit` logic if we assume `load` hasn't run or we just inspect the list.
      // Let's just test addHabit on an instance.

      // Manually init list
      provider.habits = [];

      await provider.addHabit(
        name: 'First',
        category: 'Test',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        color: '#000000',
        icon: 'A',
      );

      expect(provider.habits.length, 1);
      expect(provider.habits.first.name, 'First');

      await provider.addHabit(
        name: 'Second',
        category: 'Test',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        color: '#000000',
        icon: 'B',
      );

      expect(provider.habits.length, 2);
      expect(provider.habits.first.name, 'Second'); // Should be top
      expect(provider.habits[1].name, 'First');
    });
  });
}
