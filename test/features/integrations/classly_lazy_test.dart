import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/providers/classly_sync_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh construction is disabled and performs no credential read', () {
    final vault = _Vault();
    final provider = ClasslySyncProvider(credentialVault: vault);

    expect(provider.enabled, isFalse);
    expect(provider.baseUrl, isNull);
    expect(vault.reads, 0);
  });

  test('legacy connected users migrate only when opening lazy settings', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'classly_base_url': 'https://school.example',
    });
    final vault = _Vault(token: 'legacy-token');
    final provider = ClasslySyncProvider(credentialVault: vault);

    expect(vault.reads, 0);
    await provider.load();

    expect(provider.enabled, isTrue);
    expect(provider.legacyConnectionMigrated, isTrue);
    expect(vault.reads, 1);
    expect(
      (await SharedPreferences.getInstance()).getBool('classly_enabled'),
      isTrue,
    );
  });

  test('composition has no root provider or bundled default endpoint', () {
    final main = File('lib/main.dart').readAsStringSync();
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(main, isNot(contains('ClasslySyncProvider')));
    expect(sources, isNot(contains('classly.site')));
  });
}

final class _Vault implements ClasslyCredentialVault {
  _Vault({this.token});
  String? token;
  int reads = 0;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> readToken() async {
    reads++;
    return token;
  }

  @override
  Future<void> writeToken(String value) async => token = value;
}
