import 'dart:convert';
import 'dart:typed_data';

import 'package:habiter/features/updates/domain/update_models.dart';

Map<String, Object?> releaseJson({
  required int build,
  required String channel,
  DateTime? mandatoryAfter,
  List<Map<String, Object?>>? artifacts,
}) => {
  'version': '1.${build ~/ 100}.${build % 100}',
  'buildNumber': build,
  'channel': channel,
  'status': 'published',
  'publishedAt': '2026-08-17T12:00:00Z',
  'minimumSupportedVersion': '1.0.0',
  'mandatoryAfter': mandatoryAfter?.toUtc().toIso8601String(),
  'notes': {
    'added': ['Added $build'],
    'changed': <String>[],
    'fixed': <String>[],
    'security': <String>[],
  },
  'presentation': {
    'de': {
      'headline': 'Neu in $build',
      'summary': 'Zusammenfassung',
      'highlights': <Object?>[],
      'changes': {
        'added': ['Neu'],
        'changed': <String>[],
        'fixed': <String>[],
        'security': <String>[],
      },
    },
    'en': {
      'headline': 'New in $build',
      'summary': 'Summary',
      'highlights': <Object?>[],
      'changes': {
        'added': ['New'],
        'changed': <String>[],
        'fixed': <String>[],
        'security': <String>[],
      },
    },
  },
  'artifacts':
      artifacts ??
      [
        artifactJson(build: build, distribution: 'direct'),
        artifactJson(build: build, distribution: 'play'),
      ],
};

Map<String, Object?> artifactJson({
  required int build,
  required String distribution,
}) => {
  'platform': 'android',
  'architecture': 'universal',
  'fileName':
      'habiter-$build-${distribution == 'play' ? 'store.aab' : 'direct.apk'}',
  'signed': true,
  'distribution': distribution,
  'url': 'https://example.com/habiter-$build-$distribution',
  'sha256': List.filled(64, 'a').join(),
  'size': build,
};

Uint8List manifestPayload(List<Map<String, Object?>> releases) =>
    Uint8List.fromList(
      utf8.encode(jsonEncode({'schemaVersion': 1, 'releases': releases})),
    );

UpdateManifest manifestOf(List<Map<String, Object?>> releases) =>
    UpdateManifest.fromPayloadBytes(manifestPayload(releases));
