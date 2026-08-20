import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../application/app_block_onboarding_state.dart';

abstract interface class AppBlockOnboardingRepository {
  Future<AppBlockOnboardingState?> load();
  Future<void> save(AppBlockOnboardingState state);
}

final class KeyValueAppBlockOnboardingRepository
    implements AppBlockOnboardingRepository {
  const KeyValueAppBlockOnboardingRepository(this._store);

  static const storageKey = 'habiter_app_block_onboarding_v1';
  final KeyValueStore _store;

  @override
  Future<AppBlockOnboardingState?> load() async {
    final value = await _store.read(storageKey);
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('App Block onboarding state must be JSON.');
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException(
        'App Block onboarding state must be an object.',
      );
    }
    return AppBlockOnboardingState.fromMap(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> save(AppBlockOnboardingState state) =>
      _store.write(storageKey, jsonEncode(state.toMap()));
}
