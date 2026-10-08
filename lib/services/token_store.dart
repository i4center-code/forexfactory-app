/// Abstraction over durable auth / API-key storage.
///
/// Default implementation: [PrefsTokenStore] via SharedPreferences (see [AuthStore]).
///
/// TODO(release): swap to `flutter_secure_storage` for refresh tokens and raw
/// `apiv1_` keys before production stores. Keep this interface so only the
/// concrete class changes (no flutter_secure_storage dependency until release).
abstract class TokenStore {
  String? get accessToken;
  String? get refreshToken;
  String get deviceId;
  String? get email;
  bool get isLoggedIn;

  Future<void> saveTokens({required String access, String? refresh, String? email});
  Future<void> clear();
}

/// Marker mixin documenting the secure-storage swap point for API keys.
///
/// TODO(release): persist [StoredApiKey.raw] with flutter_secure_storage
/// (or platform Keychain/Keystore) instead of plaintext SharedPreferences.
mixin SecureApiKeyStorageHint {}
