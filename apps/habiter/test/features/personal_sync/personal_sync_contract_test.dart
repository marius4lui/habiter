import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_contract.dart';

void main() {
  group('PersonalSyncVersions', () {
    test('negotiates the supported protocol window explicitly', () {
      expect(
        PersonalSyncVersions.negotiateProtocol(1),
        PersonalSyncCompatibility.compatible,
      );
      expect(
        PersonalSyncVersions.negotiateProtocol(0),
        PersonalSyncCompatibility.serverUpgradeRequired,
      );
      expect(
        PersonalSyncVersions.negotiateProtocol(2),
        PersonalSyncCompatibility.clientUpgradeRequired,
      );
    });
  });

  group('PersonalSyncEntityId', () {
    test('uses stable encoded habit and entry identities', () {
      final habit = PersonalSyncEntityId.habit('morning/walk');
      final entry = PersonalSyncEntityId.entry('morning/walk', '2026-08-21');

      expect(habit.value, 'habit/morning%2Fwalk');
      expect(entry.value, 'entry/morning%2Fwalk/2026-08-21');
      expect(PersonalSyncEntityId.parse(habit.value), habit);
      expect(PersonalSyncEntityId.parse(entry.value), entry);
    });

    test('rejects malformed identities and impossible local dates', () {
      expect(
        () => PersonalSyncEntityId.parse('entry/habit/2026-02-31'),
        _throwsCode('invalid_entity_id'),
      );
      expect(
        () => PersonalSyncEntityId.parse('unknown/value'),
        _throwsCode('invalid_entity_id'),
      );
    });
  });

  group('PersonalSyncSettingRegistry', () {
    test('freezes the version-1 allow-list and validates every default', () {
      expect(PersonalSyncSettingRegistry.byKey.keys, <String>{
        'appearance.theme',
        'appearance.language',
        'coaching.showRecoverySupport',
        'reminders.enabled',
        'reminders.activeDayStart',
        'reminders.activeDayEnd',
        'reminders.globalDailyLimit',
        'reminders.globalMinimumSpacingMinutes',
        'reminders.quietHours',
        'reminders.calibrationEnabled',
        'reminders.ongoingLearningEnabled',
        'reminders.showLearningExplanations',
        'reminders.defaultSnoozeMinutes',
        'reminders.dailyOverview.enabled',
        'reminders.dailyOverview.time',
      });
      for (final definition in PersonalSyncSettingRegistry.definitions) {
        expect(definition.schemaVersionIntroduced, 1);
        expect(definition.sensitive, isFalse);
        expect(definition.syncEligible, isTrue);
        expect(definition.validate(definition.defaultValue), isTrue);
        expect(definition.mergePolicy, PersonalSyncMergePolicy.fieldRevision);
      }
    });

    test('accepts only normalized allow-listed values and returns a copy', () {
      final quietHours = <Object?>[
        <String, Object?>{'start': '22:00', 'end': '23:30'},
        <String, Object?>{'start': '00:30', 'end': '07:00'},
      ];
      final result =
          PersonalSyncSettingRegistry.validateValues(<String, Object?>{
            'appearance.theme': 'dark',
            'appearance.language': 'de',
            'reminders.globalDailyLimit': 12,
            'reminders.quietHours': quietHours,
          });

      quietHours.clear();
      expect(result['reminders.quietHours'], hasLength(2));
      expect(
        ((result['reminders.quietHours']! as List).first as Map)['start'],
        '00:30',
      );
      expect(
        () => result['appearance.theme'] = 'light',
        throwsUnsupportedError,
      );
    });

    test('rejects unknown and sensitive-looking setting names', () {
      expect(
        () => PersonalSyncSettingRegistry.validateValues(<String, Object?>{
          'arbitrary.preference': true,
        }),
        _throwsCode('unknown_setting'),
      );
      expect(
        () => PersonalSyncSettingRegistry.validateValues(<String, Object?>{
          'oauth.accessToken': 'secret',
        }),
        _throwsCode('sensitive_setting'),
      );
    });

    test('rejects invalid and overlapping reminder values', () {
      expect(
        () => PersonalSyncSettingRegistry.validateValues(<String, Object?>{
          'reminders.globalDailyLimit': 0,
        }),
        _throwsCode('invalid_setting'),
      );
      expect(
        () => PersonalSyncSettingRegistry.validateValues(<String, Object?>{
          'reminders.quietHours': <Object?>[
            <String, Object?>{'start': '22:00', 'end': '07:00'},
            <String, Object?>{'start': '06:00', 'end': '08:00'},
          ],
        }),
        _throwsCode('invalid_setting'),
      );
      expect(
        () => PersonalSyncSettingRegistry.validateValues(<String, Object?>{
          'reminders.quietHours': <Object?>[
            <String, Object?>{'start': '22:00', 'end': '23:00'},
            <String, Object?>{'start': '23:00', 'end': '23:30'},
          ],
        }),
        _throwsCode('invalid_setting'),
      );
    });
  });

  group('PersonalSyncEntityDocument', () {
    test('preserves additive habit fields and document metadata', () {
      final source = <String, Object?>{
        'schemaVersion': 1,
        'entityId': 'habit/habit-1',
        'deleted': false,
        'payload': <String, Object?>{
          ..._habitPayload(),
          'futureField': <String, Object?>{'enabled': true},
        },
        'futureMetadata': <String, Object?>{'origin': 'server'},
      };

      final document = PersonalSyncEntityDocument.fromMap(source);
      final encoded = document.toMap();

      expect((encoded['payload']! as Map)['futureField'], <String, Object?>{
        'enabled': true,
      });
      expect(encoded['futureMetadata'], <String, Object?>{'origin': 'server'});
    });

    test('rejects identity mismatches and nested secret-looking fields', () {
      expect(
        () => PersonalSyncEntityDocument(
          entityId: PersonalSyncEntityId.habit('other-id'),
          deleted: false,
          payload: _habitPayload(),
        ),
        _throwsCode('entity_id_mismatch'),
      );
      expect(
        () => PersonalSyncEntityDocument(
          entityId: PersonalSyncEntityId.habit('habit-1'),
          deleted: false,
          payload: <String, Object?>{
            ..._habitPayload(),
            'source': <String, Object?>{'apiKey': 'must-not-leave-device'},
          },
        ),
        _throwsCode('sensitive_payload'),
      );
    });

    test('uses habit and local date as the entry logical identity', () {
      expect(
        () => PersonalSyncEntityDocument(
          entityId: PersonalSyncEntityId.entry('habit-1', '2026-08-20'),
          deleted: false,
          payload: _entryPayload(),
        ),
        _throwsCode('entity_id_mismatch'),
      );
      final document = PersonalSyncEntityDocument(
        entityId: PersonalSyncEntityId.entry('habit-1', '2026-08-21'),
        deleted: false,
        payload: _entryPayload(),
      );
      expect(document.payload!['id'], 'local-entry-id');
    });

    test(
      'represents tombstones without payload and validates setting values',
      () {
        final tombstone = PersonalSyncEntityDocument(
          entityId: PersonalSyncEntityId.habit('habit-1'),
          deleted: true,
        );
        expect(tombstone.toMap(), <String, Object?>{
          'schemaVersion': 1,
          'entityId': 'habit/habit-1',
          'deleted': true,
        });

        expect(
          () => PersonalSyncEntityDocument(
            entityId: PersonalSyncEntityId.setting('appearance.theme'),
            deleted: false,
            payload: <String, Object?>{'value': 'neon'},
          ),
          _throwsCode('invalid_setting'),
        );
      },
    );

    test('rejects future entity schemas before accepting a payload', () {
      expect(
        () => PersonalSyncEntityDocument.fromMap(<String, Object?>{
          'schemaVersion': 2,
          'entityId': 'habit/habit-1',
          'deleted': false,
          'payload': _habitPayload(),
        }),
        _throwsCode('unsupported_entity_schema'),
      );
    });

    test('rejects non-JSON object keys with a stable contract error', () {
      expect(
        () => PersonalSyncEntityDocument(
          entityId: PersonalSyncEntityId.habit('habit-1'),
          deleted: false,
          payload: <String, Object?>{
            ..._habitPayload(),
            'futureField': <Object?, Object?>{1: 'not-json'},
          },
        ),
        _throwsCode('non_json_value'),
      );
      expect(
        () => PersonalSyncEntityDocument(
          entityId: PersonalSyncEntityId.habit('habit-1'),
          deleted: false,
          payload: <String, Object?>{
            ..._habitPayload(),
            'futureScore': double.nan,
          },
        ),
        _throwsCode('non_json_value'),
      );
      expect(
        () => PersonalSyncEntityDocument.fromMap(<String, Object?>{
          'schemaVersion': 1.5,
          'entityId': 'habit/habit-1',
          'deleted': false,
          'payload': _habitPayload(),
        }),
        _throwsCode('invalid_document'),
      );
    });
  });
}

Map<String, Object?> _habitPayload() => <String, Object?>{
  'id': 'habit-1',
  'name': 'Morning walk',
  'description': null,
  'color': '#6750A4',
  'icon': 'walk',
  'frequency': 'daily',
  'targetCount': 1,
  'category': 'Health',
  'customDays': null,
  'createdAt': '2026-08-20T10:00:00.000Z',
  'isActive': true,
  'notificationEnabled': false,
  'notificationTime': null,
};

Map<String, Object?> _entryPayload() => <String, Object?>{
  'id': 'local-entry-id',
  'habitId': 'habit-1',
  'date': '2026-08-21',
  'completed': true,
  'count': 1,
  'timestamp': '2026-08-21T08:30:00.000Z',
};

Matcher _throwsCode(String code) => throwsA(
  isA<PersonalSyncContractException>().having(
    (error) => error.code,
    'code',
    code,
  ),
);
