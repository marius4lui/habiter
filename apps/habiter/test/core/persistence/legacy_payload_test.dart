import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/models/locked_app.dart';
import 'package:habiter/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _fixture(String name) =>
    File('test/fixtures/legacy/$name').readAsStringSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService legacy compatibility', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'habiter_habits': _fixture('habits_v0.json'),
        'habiter_habit_entries': _fixture('habit_entries_v0.json'),
        'habiter_user_preferences': _fixture('user_preferences_v0.json'),
        'habiter_app_lock_config': _fixture('app_lock_config_v0.json'),
      });
    });

    test('loads all existing v0 keys without changing their meaning', () async {
      final habits = await StorageService.getHabits();
      final entries = await StorageService.getHabitEntries();
      final preferences = await StorageService.getUserPreferences();
      final appLock = await StorageService.getAppLockConfig();

      expect(habits.map((habit) => habit.id), <String>[
        'legacy-daily-water',
        'legacy-custom-reading',
      ]);
      expect(entries, hasLength(2));
      expect(preferences.theme, ThemePreference.dark);
      expect(preferences.notifications, isFalse);
      expect(preferences.language, 'de');
      expect(appLock.isEnabled, isTrue);
      expect(appLock.lockedPackageNames, <String>['com.example.social']);
      expect(appLock.requiredHabitIds, <String>['legacy-daily-water']);
    });

    test('returns an empty collection when no habit key exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      expect(await StorageService.getHabits(), isEmpty);
    });

    test(
      'updates schedule and reminder fields without losing other data',
      () async {
        await StorageService.updateHabit(
          'legacy-custom-reading',
          <String, dynamic>{
            'customDays': <int>[2, 4, 6],
            'notificationEnabled': true,
            'notificationTime': '07:05',
          },
        );

        final updated = (await StorageService.getHabits()).singleWhere(
          (habit) => habit.id == 'legacy-custom-reading',
        );
        expect(updated.customDays, <int>[2, 4, 6]);
        expect(updated.notificationEnabled, isTrue);
        expect(updated.notificationTime, '07:05');
        expect(updated.name, 'Read 10 pages');
        expect(updated.createdAt, DateTime.parse('2026-01-02T18:45:00.000Z'));
      },
    );

    test('legacy preference and app-lock JSON remain serializable', () async {
      final preferences = await StorageService.getUserPreferences();
      final appLock = await StorageService.getAppLockConfig();

      expect(
        jsonDecode(jsonEncode(preferences.toMap())),
        jsonDecode(_fixture('user_preferences_v0.json')),
      );
      expect(AppLockConfig.fromJson(appLock.toJson()).toMap(), appLock.toMap());
    });
  });
}
