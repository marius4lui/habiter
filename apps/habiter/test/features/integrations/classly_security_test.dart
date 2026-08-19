import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/domain/habit_source.dart';
import 'package:habiter/features/integrations/classly/classly_endpoint.dart';
import 'package:habiter/models/habit.dart';
import 'package:habiter/services/classly_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ClasslyEndpoint', () {
    test('accepts a public root HTTPS origin', () {
      expect(
        ClasslyEndpoint.parse('https://school.example/').origin.toString(),
        'https://school.example',
      );
    });

    test('rejects insecure, credentialed, private, and nested endpoints', () {
      for (final endpoint in <String>[
        'http://school.example',
        'https://user:secret@school.example',
        'https://localhost',
        'https://192.168.1.2',
        'https://school.example/api',
        'https://school.example:8443',
      ]) {
        expect(() => ClasslyEndpoint.parse(endpoint), throwsFormatException);
      }
    });
  });

  test('HTTP failures expose status but never the response body', () async {
    final client = ClasslyClient(
      baseUrl: 'https://school.example',
      token: 'token',
      httpClient: MockClient(
        (_) async => http.Response('{"secret":"must-not-leak"}', 500),
      ),
    );

    await expectLater(
      client.fetchEvents(),
      throwsA(
        isA<ClasslyApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having(
              (error) => error.toString(),
              'redacted message',
              isNot(contains('must-not-leak')),
            ),
      ),
    );
  });

  test('event parsing requires only fields consumed by Habiter', () async {
    final client = ClasslyClient(
      baseUrl: 'https://school.example',
      token: 'token',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'events': [
              {
                'id': 'event-42',
                'type': 'homework',
                'title': 'Worksheet',
                'date': '2026-08-21T00:00:00Z',
              },
            ],
          }),
          200,
        ),
      ),
    );

    final event = (await client.fetchEvents()).single;
    expect(event.id, 'event-42');
    expect(event.title, 'Worksheet');
    expect(event.subjectName, isNull);
  });

  test('source metadata survives JSON and unknown future fields', () {
    final habit = Habit(
      id: 'habit-1',
      name: 'Worksheet',
      color: '#000000',
      icon: 'book',
      frequency: HabitFrequency.custom,
      targetCount: 1,
      category: 'School',
      customDays: const <int>[5],
      createdAt: DateTime.utc(2026, 8, 14),
      isActive: true,
      source: HabitSourceMetadata(
        kind: HabitSourceKind.classlyCompatible,
        externalId: 'event-42',
        additionalFields: const <String, Object?>{
          'occursOn': '2026-08-14',
          'future': <Object?>['kept'],
        },
      ),
    );

    final restored = Habit.fromJson(jsonEncode(habit.toMap()));
    expect(restored.source.externalId, 'event-42');
    expect(restored.source.additionalFields['occursOn'], '2026-08-14');
    expect(restored.source.additionalFields['future'], <Object?>['kept']);
  });
}
