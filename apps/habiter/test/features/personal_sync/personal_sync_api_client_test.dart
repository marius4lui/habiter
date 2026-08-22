import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_contract.dart';
import 'package:habiter/features/personal_sync/domain/personal_sync_operation.dart';
import 'package:habiter/features/personal_sync/infrastructure/personal_sync_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('push uses a bearer header and validates aligned receipts', () async {
    final operation = _operation();
    final cursor = PersonalSyncServerCursor(generation: 'epoch-a', offset: 1);
    final remote = HttpPersonalSyncRemote(
      Uri.parse('https://sync.example.com'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, Uri.parse('https://sync.example.com/v1/push'));
        expect(request.headers['authorization'], 'Bearer access-secret');
        expect((jsonDecode(request.body) as Map)['operations'], <Object?>[
          operation.toMap(),
        ]);
        return http.Response(
          jsonEncode(<String, Object?>{
            'receipts': <Object?>[
              <String, Object?>{
                'cursor': cursor.token,
                'offset': 1,
                'duplicate': false,
                'changed': true,
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    await remote.push(<PersonalSyncOperation>[operation], 'access-secret');
    remote.close();
  });

  test(
    'pull sends bounded cursor parameters and validates operations',
    () async {
      final operation = _operation();
      final before = PersonalSyncServerCursor(generation: 'epoch-a', offset: 1);
      final after = PersonalSyncServerCursor(generation: 'epoch-a', offset: 2);
      final remote = HttpPersonalSyncRemote(
        Uri.parse('https://sync.example.com'),
        client: MockClient((request) async {
          expect(request.url.queryParameters, <String, String>{
            'cursor': before.token,
            'limit': '50',
          });
          return http.Response(
            jsonEncode(<String, Object?>{
              'operations': <Object?>[operation.toMap()],
              'cursor': after.token,
              'headOffset': 2,
              'compactionFloor': 0,
              'requiresSnapshot': false,
              'recoveryReason': 'none',
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final page = await remote.pull(
        cursor: before,
        limit: 50,
        accessToken: 'access-secret',
      );

      expect(page.operations.single.fingerprint, operation.fingerprint);
      expect(page.cursor, after);
      remote.close();
    },
  );

  test('pull fails closed on inconsistent snapshot metadata', () async {
    final cursor = PersonalSyncServerCursor(generation: 'epoch-a', offset: 2);
    final remote = HttpPersonalSyncRemote(
      Uri.parse('https://sync.example.com'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'operations': <Object?>[_operation().toMap()],
            'cursor': cursor.token,
            'headOffset': 2,
            'compactionFloor': 1,
            'requiresSnapshot': true,
            'recoveryReason': 'missing_compacted_history',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        ),
      ),
    );

    await expectLater(
      remote.pull(cursor: null, limit: 100, accessToken: 'access-secret'),
      throwsA(
        isA<PersonalSyncRemoteException>().having(
          (error) => error.code,
          'code',
          'invalid_response',
        ),
      ),
    );
    remote.close();
  });
}

PersonalSyncOperation _operation() => PersonalSyncOperation(
  kind: PersonalSyncOperationKind.create,
  revision: PersonalSyncRevision(deviceId: 'phone-a', sequence: 1),
  document: PersonalSyncEntityDocument(
    entityId: PersonalSyncEntityId.habit('habit-a'),
    deleted: false,
    payload: <String, Object?>{
      'id': 'habit-a',
      'name': 'Walk',
      'description': null,
      'color': '#6750A4',
      'icon': 'walk',
      'frequency': 'daily',
      'targetCount': 1,
      'category': 'Health',
      'customDays': null,
      'createdAt': '2026-08-22T12:00:00.000Z',
      'isActive': true,
      'notificationEnabled': false,
      'notificationTime': null,
    },
  ),
  changedFields: const <String>{
    'id',
    'name',
    'description',
    'color',
    'icon',
    'frequency',
    'targetCount',
    'category',
    'customDays',
    'createdAt',
    'isActive',
    'notificationEnabled',
    'notificationTime',
  },
);
