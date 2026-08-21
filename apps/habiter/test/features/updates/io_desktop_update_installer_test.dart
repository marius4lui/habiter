import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/features/updates/infrastructure/desktop_update_installer.dart';
import 'package:habiter/features/updates/infrastructure/io_desktop_update_installer.dart';

void main() {
  late Directory fixture;
  late Directory installRoot;
  late Directory helperRoot;
  late File executable;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('habiter-installer-test.');
    installRoot = await Directory('${fixture.path}/install').create();
    helperRoot = await Directory('${fixture.path}/updates').create();
    executable = File('${installRoot.path}/Habiter.AppImage');
    await executable.writeAsString('#!/bin/sh\nexit 0\n');
    await _writeManifest(installRoot, executable, scope: 'user');
  });

  tearDown(() async {
    if (await fixture.exists()) await fixture.delete(recursive: true);
  });

  test('Linux handoff verifies, replaces atomically, and restarts', () async {
    String? command;
    List<String>? arguments;
    final payload = File('${helperRoot.path}/next.AppImage');
    final marker = File('${fixture.path}/started');
    await payload.writeAsString(
      '#!/bin/sh\nprintf updated > "${marker.path}"\nsleep 4\n',
    );
    final digest = sha256.convert(await payload.readAsBytes()).toString();
    final installer = IoDesktopUpdateInstaller(
      helperDirectory: helperRoot,
      platformOverride: 'linux',
      environment: {'APPIMAGE': executable.path},
      processIdOverride: 999999,
      launcher: (value, args) async {
        command = value;
        arguments = args;
        return true;
      },
    );

    expect(installer.canInstall('linux'), isTrue);
    expect(
      await installer.launch(
        DesktopInstallRequest(
          platform: 'linux',
          payloadPath: payload.path,
          sha256: digest,
          size: await payload.length(),
          version: '1.8.0',
          signed: false,
          errorPath: '${helperRoot.path}/install.error',
        ),
      ),
      isTrue,
    );
    expect(command, '/bin/sh');
    final helper = File(arguments!.first);
    final script = await helper.readAsString();
    expect(script, contains('sha256sum'));
    expect(script, contains('.Habiter.AppImage.backup-'));
    expect(script, contains('kill -0'));

    final rejectedArguments = [...arguments!]
      ..[5] = List.filled(64, '0').join();
    final rejected = await Process.run(command!, rejectedArguments);
    expect(rejected.exitCode, isNot(0));
    expect(await executable.readAsString(), contains('exit 0'));
    await File('${helperRoot.path}/install.error').delete();

    final result = await Process.run(command!, arguments!);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(await executable.readAsString(), await payload.readAsString());
    expect(await marker.exists(), isTrue);
    expect(await File('${helperRoot.path}/install.error').exists(), isFalse);
  });

  test(
    'Linux handoff restores the previous AppImage on startup failure',
    () async {
      String? command;
      List<String>? arguments;
      final original = await executable.readAsString();
      final payload = File('${helperRoot.path}/broken.AppImage');
      await payload.writeAsString('#!/bin/sh\nexit 1\n');
      final digest = sha256.convert(await payload.readAsBytes()).toString();
      final error = File('${helperRoot.path}/install.error');
      final installer = IoDesktopUpdateInstaller(
        helperDirectory: helperRoot,
        platformOverride: 'linux',
        environment: {'APPIMAGE': executable.path},
        processIdOverride: 999999,
        launcher: (value, args) async {
          command = value;
          arguments = args;
          return true;
        },
      );
      await installer.launch(
        DesktopInstallRequest(
          platform: 'linux',
          payloadPath: payload.path,
          sha256: digest,
          size: await payload.length(),
          version: '1.8.0',
          signed: false,
          errorPath: error.path,
        ),
      );

      final result = await Process.run(command!, arguments!);
      expect(result.exitCode, isNot(0));
      expect(await executable.readAsString(), original);
      expect((await error.readAsString()).trim(), 'install_failed');
    },
  );

  test('ownership scope and macOS signing boundary fail closed', () async {
    await _writeManifest(installRoot, executable, scope: 'system');
    final linux = IoDesktopUpdateInstaller(
      helperDirectory: helperRoot,
      platformOverride: 'linux',
      environment: {'APPIMAGE': executable.path},
    );
    final macos = IoDesktopUpdateInstaller(
      helperDirectory: helperRoot,
      platformOverride: 'macos',
    );

    expect(linux.canInstall('linux'), isFalse);
    expect(macos.canInstall('macos'), isFalse);
  });

  test(
    'Windows handoff includes archive, publisher, and rollback guards',
    () async {
      final windowsExecutable = File('${installRoot.path}/habiter.exe');
      await windowsExecutable.writeAsBytes([77, 90]);
      await _writeManifest(installRoot, windowsExecutable, scope: 'user');
      final payload = File('${helperRoot.path}/next.zip');
      await payload.writeAsBytes([80, 75, 3, 4]);
      final digest = sha256.convert(await payload.readAsBytes()).toString();
      String? command;
      List<String>? arguments;
      final installer = IoDesktopUpdateInstaller(
        helperDirectory: helperRoot,
        platformOverride: 'windows',
        resolvedExecutable: windowsExecutable.path,
        processIdOverride: 999999,
        launcher: (value, args) async {
          command = value;
          arguments = args;
          return true;
        },
      );

      expect(installer.canInstall('windows'), isTrue);
      expect(
        await installer.launch(
          DesktopInstallRequest(
            platform: 'windows',
            payloadPath: payload.path,
            sha256: digest,
            size: await payload.length(),
            version: '1.8.0',
            signed: false,
            errorPath: '${helperRoot.path}/install.error',
          ),
        ),
        isFalse,
      );
      expect(
        await installer.launch(
          DesktopInstallRequest(
            platform: 'windows',
            payloadPath: payload.path,
            sha256: digest,
            size: await payload.length(),
            version: '1.8.0',
            signed: true,
            errorPath: '${helperRoot.path}/install.error',
          ),
        ),
        isTrue,
      );
      expect(command, 'powershell.exe');
      expect(
        arguments,
        containsAllInOrder(['-ExecutionPolicy', 'RemoteSigned']),
      );
      final helperPath = arguments![arguments!.indexOf('-File') + 1];
      final script = await File(helperPath).readAsString();
      expect(script, contains('Get-FileHash'));
      expect(script, contains('Get-AuthenticodeSignature'));
      expect(script, contains('ReparsePoint'));
      expect(script, contains(r'Move-Item -LiteralPath $backup'));
    },
  );
}

Future<void> _writeManifest(
  Directory root,
  File executable, {
  required String scope,
}) async {
  final canonicalRoot = root.resolveSymbolicLinksSync();
  final canonicalExecutable = executable.resolveSymbolicLinksSync();
  await File('${root.path}/.habiter-install.json').writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'product': 'habiter',
      'applicationId': 'dev.habiter.Habiter',
      'installId': 'test-install',
      'version': '1.7.2',
      'scope': scope,
      'canonicalInstallRoot': canonicalRoot,
      'executable': canonicalExecutable,
      'integrationPaths': <String>[],
      'pathEntry': null,
      'pathEntryAddedByInstaller': false,
    }),
  );
}
