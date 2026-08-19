import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  const expectedWorkflows = <String>{
    'quality.yml',
    'platform-builds.yml',
    'worker-deploy.yml',
    'worker-preview.yml',
    'release.yml',
    'docs-deploy.yml',
  };

  final repositoryRoot = Directory.current.parent.parent;
  File workflow(String name) =>
      File('${repositoryRoot.path}/.github/workflows/$name');

  group('GitHub Actions contracts', () {
    test('all workflow files are valid YAML mappings', () {
      for (final name in expectedWorkflows) {
        final parsed = loadYaml(workflow(name).readAsStringSync());
        expect(parsed, isA<YamlMap>(), reason: name);
      }
    });

    test('uses the six intentional custom workflows', () {
      final actual = Directory('${repositoryRoot.path}/.github/workflows')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('.yml'))
          .toSet();

      expect(actual, expectedWorkflows);
    });

    test('every workflow has concurrency and least-privilege permissions', () {
      for (final name in expectedWorkflows) {
        final content = workflow(name).readAsStringSync();

        expect(content, contains('concurrency:'), reason: name);
        expect(content, contains('permissions:'), reason: name);
        expect(
          content,
          matches(RegExp(r'contents:\s+(read|write)')),
          reason: name,
        );
      }
    });

    test('pull requests never publish releases or deploy pages', () {
      final preview = workflow('worker-preview.yml').readAsStringSync();
      expect(preview, isNot(contains('softprops/action-gh-release')));
      expect(preview, isNot(contains('--env production')));
      expect(preview, isNot(contains('|| true')));
    });

    test('worker previews use one native versioned preview worker', () {
      final preview = workflow('worker-preview.yml').readAsStringSync();

      expect(preview, contains('wrangler versions upload'));
      expect(preview, contains('--preview-alias "\$PREVIEW_ALIAS"'));
      expect(preview, contains('PREVIEW_ALIAS: pr-'));
      expect(preview, isNot(contains('wrangler deploy --env preview')));
      expect(preview, isNot(contains('habiter-release-api-pr-')));
      expect(preview, isNot(contains('wrangler delete')));
    });

    test('quality workflows expose stable required-check job names', () {
      final quality = workflow('quality.yml').readAsStringSync();
      expect(quality, contains('name: Flutter Quality'));
      expect(quality, contains('name: Worker, Release and Website Quality'));
      expect(quality, contains('quality-summary:'));
    });

    test('documentation workflows enforce the complete docs contract', () {
      final quality = workflow('quality.yml').readAsStringSync();
      final deploy = workflow('docs-deploy.yml').readAsStringSync();

      expect(quality, contains('npm run docs:check'));
      expect(deploy, contains('npm run docs:check'));
      expect(deploy, contains("'scripts/docs/validate.mjs'"));
    });

    test('release publishing preserves stable and beta channels', () {
      final release = workflow('release.yml').readAsStringSync();

      expect(
        release,
        contains('channel: \${{ steps.version.outputs.channel }}'),
      );
      expect(release, contains('PRERELEASE_ARGS+=(--prerelease)'));
      expect(
        release,
        contains(
          'gh release edit "\$TAG" --draft=false --prerelease --latest=false',
        ),
      );
      expect(
        release,
        contains(
          'gh release edit "\$TAG" --draft=false --prerelease=false --latest',
        ),
      );
      expect(release, contains('scripts/release/finalize-manifest.mjs'));
      expect(release, contains('git push origin HEAD:main'));
      expect(release, contains('for ATTEMPT in {1..30}'));
      expect(release, contains('Manifest endpoint did not converge'));
      expect(release, contains('cache_bust=\$CACHE_BUST'));
      expect(release, contains('Latest release did not converge'));
    });
  });
}
