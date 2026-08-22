import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Personal Sync credentials have no insecure storage or output path', () {
    final directory = Directory('lib/features/personal_sync');
    final sources = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(sources, isNot(contains('package:shared_preferences')));
    expect(sources, isNot(contains('SharedPreferences.getInstance')));
    expect(sources, isNot(contains('Clipboard')));
    expect(sources, isNot(contains('debugPrint')));
    expect(sources, isNot(contains('print(')));
    expect(
      File(
        'lib/features/personal_sync/infrastructure/personal_sync_secure_vault.dart',
      ).readAsStringSync(),
      allOf(
        contains('FlutterSecureStorage'),
        contains('encryptedSharedPreferences: true'),
        contains('first_unlock_this_device'),
      ),
    );
    final setup = File(
      'lib/features/personal_sync/presentation/personal_sync_settings_card.dart',
    ).readAsStringSync();
    expect(RegExp(r'\bTextField\(').allMatches(setup), hasLength(1));
    expect(setup, isNot(contains('obscureText')));
    expect(setup, isNot(contains('username')));
  });

  test('native callback bridges do not log callback URLs', () {
    final android = File(
      'android/app/src/main/kotlin/com/habiter/app/MainActivity.kt',
    ).readAsStringSync();
    final ios = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(android, contains('PERSONAL_SYNC_CHANNEL'));
    expect(android, contains('consumeInitialCallback'));
    expect(android, isNot(contains('Log.d(TAG, callback')));
    expect(ios, contains('consumePersonalSyncCallback'));
    expect(ios, isNot(contains('print(url')));
  });
}
