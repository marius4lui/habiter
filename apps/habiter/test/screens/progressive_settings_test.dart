import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings source keeps advanced integrations collapsed', () async {
    final source = await File(
      'lib/screens/settings_screen.dart',
    ).readAsString();
    expect(source, contains("Key('advanced-integrations')"));
    expect(source, contains('Optional, disabled by default'));
    expect(source, contains('Privacy & data'));
    expect(source, isNot(contains('connectWithCredentials')));
  });
}
