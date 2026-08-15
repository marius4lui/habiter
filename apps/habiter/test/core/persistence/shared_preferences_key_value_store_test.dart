import 'package:flutter_test/flutter_test.dart';
import 'package:habiter/core/persistence/shared_preferences_key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'text': 'value',
      'items': <String>['one'],
    });
  });

  test(
    'adapts supported SharedPreferences values without aliasing lists',
    () async {
      final store = SharedPreferencesKeyValueStore();

      final snapshot = await store.snapshot();
      (snapshot['items']! as List<String>).add('mutated');

      expect(await store.read('items'), <String>['one']);
      await store.write('enabled', true);
      expect(await store.read('enabled'), isTrue);
      expect(await store.contains('enabled'), isTrue);
      expect(await store.remove('enabled'), isTrue);
      expect(await store.contains('enabled'), isFalse);
    },
  );

  test('rejects values SharedPreferences cannot persist', () async {
    final store = SharedPreferencesKeyValueStore();

    await expectLater(
      store.write('map', <String, Object?>{'unsupported': true}),
      throwsArgumentError,
    );
  });
}
