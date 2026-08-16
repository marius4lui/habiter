import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile formation has no network or private platform dependencies', () {
    const profilers = <String>[
      'lib/features/reminders/application/availability_profile_engine.dart',
      'lib/features/reminders/application/dynamic_reminder_planner.dart',
    ];
    const forbiddenImports = <String>[
      "import 'dart:io'",
      'package:http',
      'package:dio',
      'package:geolocator',
      'package:location',
      'package:contacts',
      'package:calendar',
      'package:sensors',
      'package:flutter/services.dart',
    ];

    for (final path in profilers) {
      final source = File(path).readAsStringSync();
      for (final forbidden in forbiddenImports) {
        expect(
          source,
          isNot(contains(forbidden)),
          reason: '$path must not import $forbidden',
        );
      }
    }
  });
}
