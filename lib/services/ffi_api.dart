import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/models.dart';
import 'auth_store.dart';

/// High-level API: all endpoints + token refresh/retry logic.
///
/// - `token_expired` -> call /auth/refresh once, then retry the request.
/// - `invalid_token` (or refresh failure) -> clear tokens and notify
///   listeners so the UI forces a re-login.
///
/// Sales (plans/wallet/keys) live in `lib/sales/SalesApi` and reuse this class
/// for JWT refresh / store.
class FfiApi extends ChangeNotifier {
  FfiApi(this.store, {ApiClient? client}) : client = client ?? ApiClient();

  final AuthStore store;
  final ApiClient client;
  Future<bool>? _refreshing;

  bool get isLoggedIn => store.isLoggedIn;
  String get baseUrl => client.baseUrl;

  /// Allow other modules (e.g. SalesApi) to notify auth listeners after clear.
  void signalAuthChanged() => notifyListeners();

  // ---------- public ----------
  Future<Map<String, dynamic>> health() async {
    final data = await client.get(Endpoints.health);
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<CalendarResult> calendar(String type) async {
    if (!Endpoints.calendarTypes.contains(type)) {
      throw ApiException('invalid_type', 'نوع تقویم نامعتبر: $type');
    }
    return CalendarResult.fromJson(await client.get(Endpoints.calendar(type)));
  }

  /// Paid calendar via `X-API-Key: apiv1_...`.
  /// If `/data/calendar/{type}` is not deployed (404), falls back to public `/calendar/{type}`.
  Future<CalendarResult> paidCalendar(String type, {String? apiKey}) async {
    if (!Endpoints.calendarTypes.contains(type)) {
      throw ApiException('invalid_type', 'نوع تقویم نامعتبر: $type');
    }
    final key = apiKey ?? store.selectedApiKey?.raw;
    if (key == null || key.isEmpty) {
      throw const ApiException('invalid_api_key', 'کلید API انتخاب نشده است');
    }
    try {
      final data = await client.get(Endpoints.dataCalendar(type), apiKey: key);
      return CalendarResult.fromJson(data, fromPaidEndpoint: true);
    } on ApiException catch (e) {
      if (e.isNotFound || e.code == 'not_found') {
        final public = await calendar(type);
        return CalendarResult(
          public.events,
          public.generatedAt,
          fromPaidEndpoint: false,
          fallbackNote:
              'endpoint پولی (/data/calendar) هنوز روی سرور فعال نیست؛ نمایش از تقویم عمومی.',
          analyses: public.analyses,
        );
      }
      rethrow;
    }
  }

  Future<NewsPage> news({int page = 1, int perPage = 20, String? q}) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    };
    return NewsPage.fromJson(await client.get(Endpoints.news, query: query));
  }

  // ---------- auth ----------
  Future<UserProfile?> login(String email, String password) async {
    final data = await client.post(Endpoints.login, {
      'email': email.trim(),
      'password': password,
      'device_id': store.deviceId,
    });
    return _storeTokens(data, email: email.trim());
  }

  Future<UserProfile?> register({
    required String email,
    required String password,
    String? name,
    String? username,
  }) async {
    final data = await client.post(Endpoints.register, {
      'email': email.trim(),
      'password': password,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
      'device_id': store.deviceId,
      'website': '', // honeypot: must stay empty
    });
    final tokens = AuthTokens.tryParse(data);
    if (tokens != null) {
      return _storeTokens(data, email: email.trim());
    }
    return login(email, password);
  }

  Future<void> logout() async {
    final refresh = store.refreshToken;
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await client.post(Endpoints.logout, {'refresh_token': refresh});
      }
    } catch (_) {
      // Best-effort: always clear locally.
    } finally {
      await store.clear();
      notifyListeners();
    }
  }

  Future<UserProfile> me() async {
    final data = await _authed((access) => client.get(Endpoints.me, bearer: access));
    return UserProfile.fromJson(data);
  }

  Future<void> saveCreatedApiKey({
    required int id,
    required String name,
    required String display,
    required String raw,
    required List<String> calendarTypes,
  }) async {
    if (!raw.startsWith('apiv1_')) return;
    await store.saveApiKey(StoredApiKey(
      id: id,
      name: name,
      display: display,
      raw: raw,
      calendarTypes: calendarTypes,
    ));
    notifyListeners();
  }

  Future<void> removeLocalApiKey(int id) async {
    await store.removeStoredApiKey(id);
    notifyListeners();
  }

  Future<void> selectLocalApiKey(int id) async {
    await store.selectApiKey(id);
    notifyListeners();
  }

  // ---------- internals ----------
  Future<UserProfile?> _storeTokens(dynamic data, {String? email}) async {
    final tokens = AuthTokens.tryParse(data);
    if (tokens == null) {
      throw const ApiException('bad_response', 'توکن در پاسخ سرور یافت نشد');
    }
    await store.saveTokens(access: tokens.access, refresh: tokens.refresh, email: email);
    notifyListeners();
    return tokens.user;
  }

  Future<dynamic> _authed(Future<dynamic> Function(String access) call) async {
    final access = store.accessToken;
    if (access == null || access.isEmpty) {
      if (!await _refresh()) throw await _forceRelogin();
    }
    try {
      return await call(store.accessToken!);
    } on ApiException catch (e) {
      if (e.isTokenExpired) {
        if (await _refresh()) {
          try {
            return await call(store.accessToken!);
          } on ApiException catch (e2) {
            if (e2.isInvalidToken || e2.isTokenExpired) throw await _forceRelogin();
            rethrow;
          }
        }
        throw await _forceRelogin();
      }
      if (e.isInvalidToken) throw await _forceRelogin();
      rethrow;
    }
  }

  Future<bool> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refresh = store.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final data = await client.post(Endpoints.refresh, {
        'refresh_token': refresh,
        'device_id': store.deviceId,
      });
      final tokens = AuthTokens.tryParse(data);
      if (tokens == null) return false;
      await store.saveTokens(access: tokens.access, refresh: tokens.refresh);
      return true;
    } on ApiException catch (e) {
      if (e.isNetwork) rethrow;
      return false;
    }
  }

  Future<ApiException> _forceRelogin() async {
    await store.clear();
    notifyListeners();
    return const ApiException('invalid_token', 'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.');
  }
}
