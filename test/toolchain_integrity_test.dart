import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  const flutterVersion = '3.44.8';
  const nodeVersion = '24.13.1';
  const javaVersion = '17';
  const pnpmVersion = '11.21.0';

  group('toolchain pins', () {
    test('declare one Flutter, Node, Java and pnpm version', () {
      final fvm =
          jsonDecode(File('.fvmrc').readAsStringSync()) as Map<String, dynamic>;
      final package =
          jsonDecode(File('landing_page/package.json').readAsStringSync())
              as Map<String, dynamic>;

      expect(fvm['flutter'], flutterVersion);
      expect(File('.node-version').readAsStringSync().trim(), nodeVersion);
      expect(File('.java-version').readAsStringSync().trim(), javaVersion);
      expect(package['packageManager'], 'pnpm@$pnpmVersion');
      expect(File('pubspec.lock').existsSync(), isTrue);
    });

    test('all custom workflows use the pinned Flutter and Java versions', () {
      final workflows = Directory('.github/workflows')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.yml'));

      for (final workflow in workflows) {
        final content = workflow.readAsStringSync();
        for (final match in RegExp(
          r'''flutter-version:\s*['"]?([^'"\s]+)''',
        ).allMatches(content)) {
          expect(match.group(1), flutterVersion, reason: workflow.path);
        }
        for (final match in RegExp(
          r'''java-version:\s*['"]?([^'"\s]+)''',
        ).allMatches(content)) {
          expect(match.group(1), javaVersion, reason: workflow.path);
        }
      }
    });

    test('pnpm native build policy is explicit', () {
      final workspace =
          loadYaml(File('landing_page/pnpm-workspace.yaml').readAsStringSync())
              as YamlMap;
      final allowBuilds = workspace['allowBuilds'] as YamlMap;

      expect(allowBuilds['sharp'], isTrue);
      expect(allowBuilds['unrs-resolver'], isTrue);
      expect(workspace.containsKey('ignoredBuiltDependencies'), isFalse);
    });
  });
}
