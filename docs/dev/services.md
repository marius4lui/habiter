# Services

## StorageService

Handles local data persistence using SharedPreferences.

```dart
await StorageService.addHabit(habit);
final habits = await StorageService.getHabits();
```

## ClasslyClient

API client for Classly integration.

```dart
final client = ClasslyClient(baseUrl: 'https://classly.site', token: token);
final events = await client.fetchEvents();
```

## NotificationService

Manages local notifications for habit reminders.

```dart
await NotificationService.instance.scheduleHabitNotification(habit);
```
