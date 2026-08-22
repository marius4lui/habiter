import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/personal_sync_connection.dart';

abstract interface class PersonalSyncSecureVault {
  Future<PersonalSyncPendingAuthorization?> readPending();
  Future<void> writePending(PersonalSyncPendingAuthorization pending);
  Future<void> deletePending();
  Future<PersonalSyncConnection?> readConnection();
  Future<void> writeConnection(PersonalSyncConnection connection);
  Future<void> deleteConnection();
}

final class FlutterPersonalSyncSecureVault implements PersonalSyncSecureVault {
  const FlutterPersonalSyncSecureVault({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _pendingKey = 'personal_sync.pending.v1';
  static const _connectionKey = 'personal_sync.connection.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<PersonalSyncPendingAuthorization?> readPending() async {
    final value = await _storage.read(key: _pendingKey);
    return value == null
        ? null
        : PersonalSyncPendingAuthorization.fromJson(value);
  }

  @override
  Future<void> writePending(PersonalSyncPendingAuthorization pending) =>
      _storage.write(key: _pendingKey, value: pending.toJson());

  @override
  Future<void> deletePending() => _storage.delete(key: _pendingKey);

  @override
  Future<PersonalSyncConnection?> readConnection() async {
    final value = await _storage.read(key: _connectionKey);
    return value == null ? null : PersonalSyncConnection.fromJson(value);
  }

  @override
  Future<void> writeConnection(PersonalSyncConnection connection) =>
      _storage.write(key: _connectionKey, value: connection.toJson());

  @override
  Future<void> deleteConnection() => _storage.delete(key: _connectionKey);
}
