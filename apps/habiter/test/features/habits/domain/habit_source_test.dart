import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/habits/domain/habit_source.dart';

void main() {
  test('source metadata preserves unknown future fields', () {
    final source = HabitSourceMetadata.fromMap(<String, Object?>{
      'kind': 'classlyCompatible',
      'externalId': 'event-42',
      'futureProviderField': <String, Object?>{'revision': 3},
    });

    expect(source.kind, HabitSourceKind.classlyCompatible);
    expect(source.externalId, 'event-42');
    expect(source.toMap(), <String, Object?>{
      'futureProviderField': <String, Object?>{'revision': 3},
      'kind': 'classlyCompatible',
      'externalId': 'event-42',
    });
  });

  test('unknown source kinds remain roundtrippable', () {
    final source = HabitSourceMetadata.fromMap(<String, Object?>{
      'kind': 'futureIntegration',
      'externalId': 'future-1',
    });

    expect(source.kind, HabitSourceKind.unknown);
    expect(source.originalKind, 'futureIntegration');
    expect(source.toMap()['kind'], 'futureIntegration');
  });
}
