import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/classly_client.dart';
import '../services/classly_oauth_service.dart';

/// Manages Classly connection (base URL + token) and sync state.
class ClasslySyncProvider extends ChangeNotifier {
  static const _baseUrlKey = 'classly_base_url';
  static const _lastSyncKey = 'classly_last_sync';
  static const _tokenKey = 'classly_token';
  static const _autoSyncIntervalKey = 'classly_auto_sync_interval';
  static const defaultBaseUrl = 'https://classly.site';

  final _secureStorage = const FlutterSecureStorage();

  String? _baseUrl;
  String? _token;
  DateTime? _lastSync;
  bool _isSyncing = false;
  bool _isConnecting = false;
  String? _lastError;
  List<ClasslyEvent> _events = [];
  int _autoSyncMinutes = 0; // 0 = disabled
  Timer? _autoSyncTimer;

  String? get baseUrl => _baseUrl;
  String? get token => _token;
  DateTime? get lastSync => _lastSync;
  bool get isSyncing => _isSyncing;
  bool get isConnecting => _isConnecting;
  String? get lastError => _lastError;
  List<ClasslyEvent> get events => List.unmodifiable(_events);
  int get autoSyncMinutes => _autoSyncMinutes;
  bool get isConnected => _baseUrl != null && _token != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey);
    final lastSyncString = prefs.getString(_lastSyncKey);
    if (lastSyncString != null) {
      _lastSync = DateTime.tryParse(lastSyncString);
    }
    _autoSyncMinutes = prefs.getInt(_autoSyncIntervalKey) ?? 0;
    _token = await _secureStorage.read(key: _tokenKey);
    
    // Start auto-sync if enabled and connected
    if (_autoSyncMinutes > 0 && isConnected) {
      _startAutoSync();
    }
    
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
    
    // Restart auto-sync with new connection
    if (_autoSyncMinutes > 0) {
      _startAutoSync();
    }
    
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

  Future<void> connectWithOAuth({required String baseUrl}) async {
    if (_isConnecting) return;
    _isConnecting = true;
    _lastError = null;
    notifyListeners();

    try {
      final cleanedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final oauthService = ClasslyOAuthService();
      final client = ClasslyClient(baseUrl: cleanedBaseUrl);
      
      final tokenData = await oauthService.authenticate(
        baseUrl: cleanedBaseUrl,
        client: client,
      );
      
      final token = tokenData['access_token'] as String;
      // You can also extract 'class_id' or others from tokenData if needed
      
      await connect(baseUrl: cleanedBaseUrl, token: token);
      
      // Automatically sync after successful OAuth login
      await sync();
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _stopAutoSync();
    
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

  Future<void> setAutoSyncInterval(int minutes) async {
    _autoSyncMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoSyncIntervalKey, minutes);
    
    _stopAutoSync();
    if (minutes > 0 && isConnected) {
      _startAutoSync();
    }
    
    notifyListeners();
  }

  void _startAutoSync() {
    _stopAutoSync();
    if (_autoSyncMinutes <= 0) return;
    
    _autoSyncTimer = Timer.periodic(
      Duration(minutes: _autoSyncMinutes),
      (_) => sync(),
    );
    debugPrint('ClasslySyncProvider: Auto-sync started every $_autoSyncMinutes min');
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
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
      debugPrint('ClasslySync: Starting sync...');
      debugPrint('ClasslySync: Base URL: $_baseUrl');
      debugPrint('ClasslySync: Token present: ${_token != null}');
      debugPrint('ClasslySync: Last sync: $_lastSync');
      debugPrint('ClasslySync: Current events count: ${_events.length}');
      
      final client = ClasslyClient(baseUrl: _baseUrl!, token: _token);
      
      // If we have no events yet, do a full sync (no time filter)
      // Otherwise, only fetch updates since last sync
      final DateTime? syncSince = _events.isEmpty ? null : _lastSync;
      
      debugPrint('ClasslySync: Fetching events with updatedSince: $syncSince');
      
      final events = await client.fetchEvents(
        updatedSince: syncSince,
        limit: 500,
      );
      
      debugPrint('ClasslySync: Fetched ${events.length} events');
      
      // Sort events by date (newest first)
      events.sort((a, b) {
        final dateA = a.date ?? a.createdAt ?? DateTime(1970);
        final dateB = b.date ?? b.createdAt ?? DateTime(1970);
        return dateB.compareTo(dateA); // Descending order
      });
      
      // If this is an incremental sync, merge with existing events
      if (syncSince != null && events.isNotEmpty) {
        // Add new/updated events, avoiding duplicates using a Map
        final eventMap = {for (var e in _events) e.id: e};
        for (var e in events) {
          eventMap[e.id] = e; // Overwrite existing with new
        }
        
        _events = eventMap.values.toList();
        
        // Re-sort to ensure correct order after merge
        _events.sort((a, b) {
          final dateA = a.date ?? a.createdAt ?? DateTime(1970);
          final dateB = b.date ?? b.createdAt ?? DateTime(1970);
          return dateB.compareTo(dateA); // Descending order
        });
        
        debugPrint('ClasslySync: Merged events, total: ${_events.length}');
      } else {
        _events = events;
      }
      
      _lastSync = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, _lastSync!.toIso8601String());
      
      debugPrint('ClasslySync: Sync complete. Total events: ${_events.length}');
    } catch (e, stackTrace) {
      debugPrint('ClasslySync: Error during sync: $e');
      debugPrint('ClasslySync: Stack trace: $stackTrace');
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _stopAutoSync();
    super.dispose();
  }
}
