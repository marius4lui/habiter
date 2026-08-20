import '../../../models/habit.dart';

enum HabitHubDestination {
  today,
  createHabit,
  analytics,
  appLock,
  rhythm,
  updates,
  settings,
}

const habitHubDestinations = <HabitHubDestination>[
  HabitHubDestination.today,
  HabitHubDestination.createHabit,
  HabitHubDestination.analytics,
  HabitHubDestination.appLock,
  HabitHubDestination.rhythm,
  HabitHubDestination.updates,
  HabitHubDestination.settings,
];

Habit? latestActiveHabit(Iterable<Habit> habits) {
  Habit? latest;
  for (final habit in habits) {
    if (!habit.isActive) continue;
    if (latest == null || habit.createdAt.isAfter(latest.createdAt)) {
      latest = habit;
    }
  }
  return latest;
}
