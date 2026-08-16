import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import 'onboarding_state.dart';

abstract interface class OnboardingRepository {
  Future<OnboardingState?> load();

  Future<void> save(OnboardingState state);
}

final class KeyValueOnboardingRepository implements OnboardingRepository {
  const KeyValueOnboardingRepository(this._store);

  static const storageKey = 'habiter_onboarding_v2';

  final KeyValueStore _store;

  @override
  Future<OnboardingState?> load() async {
    final value = await _store.read(storageKey);
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Onboarding state must be JSON text.');
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Onboarding state must be a JSON object.');
    }
    return OnboardingState.fromMap(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> save(OnboardingState state) =>
      _store.write(storageKey, jsonEncode(state.toMap()));
}
