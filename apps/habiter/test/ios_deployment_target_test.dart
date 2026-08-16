import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final projectRoot = Directory.current;

  test('all committed iOS deployment targets support home_widget', () {
    final project = File(
      '${projectRoot.path}/ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final frameworkInfo = File(
      '${projectRoot.path}/ios/Flutter/AppFrameworkInfo.plist',
    ).readAsStringSync();

    final deploymentTargets = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);',
    ).allMatches(project).map((match) => match.group(1)).toList();

    expect(deploymentTargets, isNotEmpty);
    expect(deploymentTargets, everyElement('14.0'));
    expect(
      frameworkInfo,
      contains('<key>MinimumOSVersion</key>\n  <string>14.0</string>'),
    );
  });
}
