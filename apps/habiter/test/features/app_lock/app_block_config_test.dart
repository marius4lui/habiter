import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/app_lock/domain/app_block_config.dart';
import 'package:habiter/features/app_lock/domain/app_block_rule.dart';

void main() {
  test('migrates a legacy all-habits config to per-app general rules', () {
    final config = AppBlockConfig.fromMap(<String, dynamic>{
      'isEnabled': true,
      'lockedApps': <Map<String, Object?>>[
        <String, Object?>{
          'packageName': 'social.example',
          'appName': 'Social',
          'isLocked': true,
        },
      ],
      'lockUntilAllHabitsComplete': true,
    });

    expect(config.isEnabled, isTrue);
    expect(config.rules, hasLength(1));
    expect(config.rules.single.requirement, isA<GeneralRequirement>());
    expect(config.toMap(), containsPair('version', 1));
    expect(config.toMap(), isNot(contains('lockedApps')));
  });

  test('migrates legacy selected habits to every protected app', () {
    final config = AppBlockConfig.fromMap(<String, dynamic>{
      'lockedApps': <Map<String, Object?>>[
        <String, Object?>{
          'packageName': 'video.example',
          'appName': 'Video',
          'isLocked': true,
        },
        <String, Object?>{
          'packageName': 'ignored.example',
          'appName': 'Ignored',
          'isLocked': false,
        },
      ],
      'lockUntilAllHabitsComplete': false,
      'requiredHabitIds': <String>['read', 'move'],
    });

    final requirement = config.rules.single.requirement as HabitRequirement;
    expect(requirement.habitIds, <String>{'read', 'move'});
    expect(config.lockedPackageNames, <String>['video.example']);
  });

  test('versioned per-app rules roundtrip without losing requirements', () {
    final original = AppBlockConfig(
      isEnabled: true,
      rules: <AppBlockRule>[
        const AppBlockRule(
          packageName: 'social.example',
          appName: 'Social',
          requirement: GeneralRequirement(),
        ),
        AppBlockRule(
          packageName: 'video.example',
          appName: 'Video',
          requirement: HabitRequirement(<String>['read']),
        ),
      ],
    );

    final restored = AppBlockConfig.fromJson(original.toJson());
    expect(restored.toMap(), original.toMap());
  });
}
