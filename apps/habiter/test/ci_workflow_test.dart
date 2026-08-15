import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  const expectedWorkflows = <String>{
    'docs.yml',
    'flutter_quality.yml',
    'landing_quality.yml',
    'platform_builds.yml',
  };

  group('GitHub Actions contracts', () {
    test('all workflow files are valid YAML mappings', () {
      for (final name in expectedWorkflows) {
        final parsed = loadYaml(
          File('.github/workflows/$name').readAsStringSync(),
        );
        expect(parsed, isA<YamlMap>(), reason: name);
      }
    });

    test('uses the four intentional custom workflows', () {
      final actual = Directory('.github/workflows')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('.yml'))
          .toSet();

      expect(actual, expectedWorkflows);
    });

    test('every workflow has concurrency and least-privilege permissions', () {
      for (final name in expectedWorkflows) {
        final content = File('.github/workflows/$name').readAsStringSync();

        expect(content, contains('concurrency:'), reason: name);
        expect(content, contains('permissions:'), reason: name);
        expect(content, contains('contents: read'), reason: name);
      }
    });

    test('pull requests never publish releases or deploy pages', () {
      final combined = expectedWorkflows
          .map((name) => File('.github/workflows/$name').readAsStringSync())
          .join('\n');

      expect(combined, isNot(contains('softprops/action-gh-release')));
      expect(combined, isNot(contains('release:')));
      expect(combined, isNot(contains('|| true')));

      final docs = File('.github/workflows/docs.yml').readAsStringSync();
      expect(docs, contains("github.event_name == 'push'"));
    });

    test('quality workflows expose stable required-check job names', () {
      final flutter = File(
        '.github/workflows/flutter_quality.yml',
      ).readAsStringSync();
      final landing = File(
        '.github/workflows/landing_quality.yml',
      ).readAsStringSync();

      expect(flutter, contains('name: Flutter Quality'));
      expect(flutter, contains('quality:'));
      expect(landing, contains('name: Landing Quality'));
      expect(landing, contains('quality:'));
    });
  });
}
