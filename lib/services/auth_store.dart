import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'token_store.dart';

/// Persists access/refresh tokens, device id, and locally saved apiv1_ keys.
///
/// SharedPreferences is app-private but NOT encrypted.
/// TODO(release): implement a `SecureTokenStore` with `flutter_secure_storage`
/// for refresh tokens + raw apiv1_ keys (see README Release checklist).
class AuthStore implements TokenStore, SecureApiKeyStorageHint {
  AuthStore._(this._prefs);

  static const _kAccess = 'ffi.access_token';
  static const _kRefresh = 'ffi.refresh_token';
  static const _kDevice = 'ffi.device_id';
  static const _kEmail = 'ffi.email';
  static const _kStoredKeys = 'ffi.stored_api_keys';
  static const _kSelectedKeyId = 'ffi.selected_api_key_id';

  final SharedPreferences _prefs;

  static Future<AuthStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AuthStore._(prefs);
    if ((prefs.getString(_kDevice) ?? '').isEmpty) {
      await prefs.setString(_kDevice, const Uuid().v4());
    }
    return store;
  }

  @override
  String? get accessToken => _prefs.getString(_kAccess);
  @override
  String? get refreshToken => _prefs.getString(_kRefresh);
  @override
  String get deviceId => _prefs.getString(_kDevice) ?? '';
  @override
  String? get email => _prefs.getString(_kEmail);
  @override
  bool get isLoggedIn => (refreshToken ?? '').isNotEmpty;

  @override
  Future<void> saveTokens({required String access, String? refresh, String? email}) async {
    await _prefs.setString(_kAccess, access);
    if (refresh != null && refresh.isNotEmpty) await _prefs.setString(_kRefresh, refresh);
    if (email != null) await _prefs.setString(_kEmail, email);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kEmail);
    // Keep device_id and any locally saved API keys (user may re-login).
  }

  // ---------- locally saved raw apiv1_ keys (for paid calendar) ----------

  List<StoredApiKey> get storedApiKeys {
    final raw = _prefs.getString(_kStoredKeys);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => StoredApiKey.fromJson(Map<String, dynamic>.from(e)))
          .where((k) => k.raw.startsWith('apiv1_'))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveApiKey(StoredApiKey key) async {
    final keys = storedApiKeys.where((k) => k.id != key.id).toList()..add(key);
    await _prefs.setString(_kStoredKeys, jsonEncode(keys.map((k) => k.toJson()).toList()));
    await _prefs.setInt(_kSelectedKeyId, key.id);
  }

  Future<void> removeStoredApiKey(int id) async {
    final keys = storedApiKeys.where((k) => k.id != id).toList();
    await _prefs.setString(_kStoredKeys, jsonEncode(keys.map((k) => k.toJson()).toList()));
    if (selectedApiKeyId == id) await _prefs.remove(_kSelectedKeyId);
  }

  int? get selectedApiKeyId => _prefs.getInt(_kSelectedKeyId);

  StoredApiKey? get selectedApiKey {
    final id = selectedApiKeyId;
    final keys = storedApiKeys;
    if (id != null) {
      for (final k in keys) {
        if (k.id == id) return k;
      }
    }
    return keys.isEmpty ? null : keys.last;
  }

  Future<void> selectApiKey(int id) async {
    await _prefs.setInt(_kSelectedKeyId, id);
  }
}
