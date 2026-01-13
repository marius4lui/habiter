import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/classly_client.dart';

/// Manages Classly connection (base URL + token) and sync state.
class ClasslySyncProvider extends ChangeNotifier {
  static const _baseUrlKey = 'classly_base_url';
  static const _lastSyncKey = 'classly_last_sync';
  static const _tokenKey = 'classly_token';

  final _secureStorage = const FlutterSecureStorage();

  String? _baseUrl;
  String? _token;
  DateTime? _lastSync;
  bool _isSyncing = false;
  bool _isConnecting = false;
  String? _lastError;
  List<ClasslyEvent> _events = [];

  String? get baseUrl => _baseUrl;
  String? get token => _token;
  DateTime? get lastSync => _lastSync;
  bool get isSyncing => _isSyncing;
  bool get isConnecting => _isConnecting;
  String? get lastError => _lastError;
  List<ClasslyEvent> get events => List.unmodifiable(_events);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey);
    final lastSyncString = prefs.getString(_lastSyncKey);
    if (lastSyncString != null) {
      _lastSync = DateTime.tryParse(lastSyncString);
    }
    _token = await _secureStorage.read(key: _tokenKey);
    notifyListeners();
  }

  Future<void> connect({required String baseUrl, required String token}) async {
    final cleanedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _baseUrl = cleanedBaseUrl;
    _token = token.trim();
    _lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, cleanedBaseUrl);
    await _secureStorage.write(key: _tokenKey, value: _token);
    notifyListeners();
  }

  Future<void> connectWithCredentials({
    required String baseUrl,
    required String email,
    required String password,
    int? expiresInDays,
  }) async {
    if (_isConnecting) return;
    _isConnecting = true;
    _lastError = null;
    notifyListeners();

    try {
      final cleanedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final client = ClasslyClient(baseUrl: cleanedBaseUrl);
      final token = await client.issueToken(
        email: email.trim(),
        password: password,
        expiresInDays: expiresInDays,
      );
      await connect(baseUrl: cleanedBaseUrl, token: token);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _baseUrl = null;
    _token = null;
    _events = [];
    _lastSync = null;
    _lastError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    await prefs.remove(_lastSyncKey);
    await _secureStorage.delete(key: _tokenKey);
    notifyListeners();
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    if (_baseUrl == null || _token == null) {
      _lastError = 'Fehlende Verbindungseinstellungen';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final client = ClasslyClient(baseUrl: _baseUrl!, token: _token);
      final events = await client.fetchEvents(updatedSince: _lastSync);
      _events = events;
      _lastSync = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, _lastSync!.toIso8601String());
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
