import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../models/habit.dart';
import '../../habits/application/habit_repository.dart';
import 'personal_sync_engine_state.dart';

final class PersonalSyncRecoveryArtifact {
  PersonalSyncRecoveryArtifact._({
    required this.createdAt,
    required this.reason,
    required this.payload,
    required this.sha256Digest,
  });

  factory PersonalSyncRecoveryArtifact.create({
    required DateTime createdAt,
    required String reason,
    required HabitRepositoryDraft draft,
    required PersonalSyncEngineState engineState,
  }) {
    final payload = <String, Object?>{
      'habits': draft.habits.map((habit) => habit.toMap()).toList(),
      'entries': draft.entries.map((entry) => entry.toMap()).toList(),
      'engineState': jsonDecode(engineState.toStorage()),
    };
    return PersonalSyncRecoveryArtifact._(
      createdAt: createdAt.toUtc(),
      reason: reason,
      payload: payload,
      sha256Digest: _digest(payload),
    );
  }

  factory PersonalSyncRecoveryArtifact.fromStorage(Object? value) {
    if (value is! String) {
      throw const FormatException('invalid recovery artifact');
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('invalid recovery artifact');
    }
    final map = Map<String, Object?>.from(decoded);
    final createdAt = map['createdAt'];
    final reason = map['reason'];
    final payloadValue = map['payload'];
    final digest = map['sha256'];
    if (map.length != 5 ||
        map['schemaVersion'] != 1 ||
        createdAt is! String ||
        reason is! String ||
        reason.isEmpty ||
        payloadValue is! Map ||
        digest is! String) {
      throw const FormatException('invalid recovery artifact');
    }
    final payload = Map<String, Object?>.from(payloadValue);
    if (_digest(payload) != digest) {
      throw const FormatException('recovery artifact checksum mismatch');
    }
    final parsedAt = DateTime.tryParse(createdAt)?.toUtc();
    final habits = payload['habits'];
    final entries = payload['entries'];
    final engine = payload['engineState'];
    if (parsedAt == null ||
        habits is! List ||
        entries is! List ||
        engine is! Map) {
      throw const FormatException('invalid recovery artifact payload');
    }
    for (final habit in habits) {
      Habit.fromMap(Map<String, dynamic>.from(habit as Map));
    }
    for (final entry in entries) {
      HabitEntry.fromMap(Map<String, dynamic>.from(entry as Map));
    }
    PersonalSyncEngineState.fromStorage(jsonEncode(engine));
    return PersonalSyncRecoveryArtifact._(
      createdAt: parsedAt,
      reason: reason,
      payload: payload,
      sha256Digest: digest,
    );
  }

  final DateTime createdAt;
  final String reason;
  final Map<String, Object?> payload;
  final String sha256Digest;

  String toStorage() => jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'createdAt': createdAt.toIso8601String(),
    'reason': reason,
    'payload': payload,
    'sha256': sha256Digest,
  });
}

String _digest(Map<String, Object?> payload) =>
    sha256.convert(utf8.encode(jsonEncode(_canonical(payload)))).toString();

Object? _canonical(Object? value) => switch (value) {
  Map<Object?, Object?> map => <String, Object?>{
    for (final key in map.keys.cast<String>().toList()..sort())
      key: _canonical(map[key]),
  },
  List<Object?> list => list.map(_canonical).toList(),
  _ => value,
};
