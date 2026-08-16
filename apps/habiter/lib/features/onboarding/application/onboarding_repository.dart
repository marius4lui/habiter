import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/persistence/storage_envelope.dart';
import 'onboarding_state.dart';

abstract interface class OnboardingRepository {
  Future<OnboardingState?> load();

  Future<void> save(OnboardingState state);

  Future<bool> hasPriorProductData();
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

  @override
  Future<bool> hasPriorProductData() async {
    final backupValue = await _store.read(StorageEnvelope.backupKey);
    if (backupValue is String) {
      final decoded = jsonDecode(backupValue);
      if (decoded is Map && decoded['raw'] is Map) {
        if ((decoded['raw'] as Map).isNotEmpty) return true;
      }
    }
    final envelopeValue = await _store.read(StorageEnvelope.storageKey);
    if (envelopeValue is! String) return false;
    final envelope = StorageEnvelope.fromJson(envelopeValue);
    return envelope.data.isNotEmpty;
  }
}
