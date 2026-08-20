import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/home/application/habit_hub_model.dart';
import 'package:habiter/models/habit.dart';

void main() {
  test('hub destinations keep the product navigation order', () {
    expect(habitHubDestinations, const <HabitHubDestination>[
      HabitHubDestination.today,
      HabitHubDestination.createHabit,
      HabitHubDestination.analytics,
      HabitHubDestination.appLock,
      HabitHubDestination.rhythm,
      HabitHubDestination.updates,
      HabitHubDestination.settings,
    ]);
  });

  test('latest active habit is selected without mutating provider order', () {
    final original = <Habit>[
      _habit('older', DateTime.utc(2026, 8, 1)),
      _habit('archived-newest', DateTime.utc(2026, 8, 20), active: false),
      _habit('newer', DateTime.utc(2026, 8, 12)),
    ];
    final orderBefore = List<Habit>.of(original);

    final selected = latestActiveHabit(original);

    expect(selected?.id, 'newer');
    expect(original, orderedEquals(orderBefore));
    expect(identical(original[0], orderBefore[0]), isTrue);
  });

  test('latest active habit is absent when every habit is inactive', () {
    expect(
      latestActiveHabit(<Habit>[
        _habit('paused', DateTime.utc(2026, 8, 2), active: false),
        _habit('archived', DateTime.utc(2026, 8, 3), active: false),
      ]),
      isNull,
    );
  });
}

Habit _habit(String id, DateTime createdAt, {bool active = true}) => Habit(
  id: id,
  name: id,
  color: '#356859',
  icon: 'H',
  frequency: HabitFrequency.daily,
  targetCount: 1,
  category: 'Test',
  createdAt: createdAt,
  isActive: active,
);
