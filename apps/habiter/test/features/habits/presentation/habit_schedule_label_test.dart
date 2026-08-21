import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/presentation/habit_schedule_label.dart';
import 'package:habiter/l10n/app_localizations_en.dart';
import 'package:habiter/models/habit.dart';

void main() {
  test('invalid legacy schedule returns a localized readable fallback', () {
    final habit = Habit(
      id: 'training',
      name: 'Training',
      color: '#6B8E7A',
      icon: '🏋️',
      frequency: HabitFrequency.custom,
      targetCount: 3,
      category: 'Health',
      customDays: const <int>[],
      createdAt: DateTime.utc(2026, 8, 20),
      isActive: true,
    );

    final label = localizedHabitSchedule(AppLocalizationsEn(), habit);

    expect(label, 'Schedule unavailable');
    expect(label, isNot(contains('Closure')));
    expect(label, isNot(contains('Function')));
    expect(label, isNot(contains('onDays')));
  });
}
