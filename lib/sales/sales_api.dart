import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/models.dart' show AuthTokens;
import '../services/ffi_api.dart';
import 'models.dart';

/// Sales-specific exception with optional [retryAfterSeconds] (Retry-After).
/// Uses [ApiException.displayMessage] / [mapSalesErrorMessage] for Persian copy.
class SalesApiException extends ApiException {
  SalesApiException(
    super.code,
    super.message, {
    super.statusCode,
    super.fields,
    super.retryAfterSeconds,
  });

  bool get isIdempotencyConflict => code == 'idempotency_conflict';
  bool get isNotRenewable => code == 'not_renewable';
  bool get isKeyLimitReached => code == 'key_limit_reached';
  bool get isSubscriptionRequired => code == 'subscription_required';
  bool get isValidation => code == 'validation_error';
  @override
  bool get isConflict =>
      statusCode == 409 ||
      code == 'idempotency_conflict' ||
      code == 'key_limit_reached' ||
      code == 'code_taken';

  /// Always Persian via [mapSalesErrorMessage] (QUOTA_NOTES); never raw English server text.
  @override
  String get displayMessage => mapSalesErrorMessage(
        code,
        message,
        fields: fields,
        retryAfterSeconds: retryAfterSeconds,
      );

  @override
  String toString() =>
      'SalesApiException($code, $message, status=$statusCode, retryAfter=$retryAfterSeconds)';
}

/// UI helper: prefer [ApiException.displayMessage] (Persian) over raw [Object.toString].
String salesErrorText(Object error) {
  if (error is ApiException) return error.displayMessage;
  return 'ارتباط برقرار نشد. دوباره تلاش کنید.';
}

/// Map backend error codes to Persian UI messages (supplements [ApiException.displayMessage]).
String mapSalesErrorMessage(
  String code,
  String serverMessage, {
  Map<String, String>? fields,
  int? retryAfterSeconds,
}) {
  // Canonical Persian copy — keep in sync with ApiException.displayMessage (402/403/409/429).
  switch (code) {
    case 'insufficient_balance': // 402
      return 'برای خرید این پلن موجودی کیف پولتان کم است. لطفاً از پشتیبانی شارژ حساب بگیرید و دوباره تلاش کنید — support@forexfactoryiran.ir';
    case 'idempotency_conflict': // 409
      return 'این درخواست قبلاً با همین شناسه ثبت شده؛ نتیجهٔ قبلی را ببینید و دوباره دکمه را نزنید.';
    case 'not_renewable': // 409 — CANCEL_RENEW
      return 'این اشتراک لغو شده است. برای ادامه یک پلن را دوباره بخرید.';
    case 'already_cancelled': // 409
      return 'این اشتراک از قبل لغو شده است.';
    case 'key_limit_reached': // 409
      return 'به سقف تعداد کلیدهای فعال این اشتراک رسیده‌اید؛ یک کلید قدیمی را باطل کنید یا صبر کنید تا جا خالی شود.';
    case 'code_taken': // 409
      return 'این کد پلن قبلاً استفاده شده است.';
    case 'subscription_required': // 403
      return 'مدت پلن API به پایان رسیده است. برای ادامه، یکی از پلن‌ها را دوباره بخرید.';
    case 'subscription_expired': // 403
      return 'مدت پلن API به پایان رسیده است. برای ادامه، یکی از پلن‌ها را دوباره بخرید.';
    case 'plan_scope': // 403
      return 'این نوع تقویم در پلن شما نیست.';
    case 'not_found':
      return 'مورد درخواستی یافت نشد.';
    case 'user_not_found':
      return 'کاربر یافت نشد.';
    case 'forbidden': // 403
      return 'دسترسی مجاز نیست.';
    case 'invalid_json':
      return 'درخواست نامعتبر است.';
    case 'rate_limited': // 429 — QUOTA_NOTES
    case 'quota_exceeded':
      if (retryAfterSeconds != null && retryAfterSeconds > 0) {
        return 'سقف درخواست روزانهٔ پلن شما پر شده. حدود ${toPersianDigits('$retryAfterSeconds')} ثانیه دیگر دوباره می‌توانید درخواست بفرستید — یا فردا پس از صفر شدن شمارندهٔ روزانه.';
      }
      return 'سقف درخواست روزانهٔ پلن شما پر شده. لطفاً فردا دوباره تلاش کنید یا پلن با سقف بالاتر بخرید.';
    case 'validation_error':
      if (fields != null && fields.isNotEmpty) {
        final parts = fields.entries.map((e) => '${e.key}: ${e.value}').join('؛ ');
        return 'خطای اعتبارسنجی — $parts';
      }
      return 'اطلاعات واردشده معتبر نیست';
    case 'token_expired':
    case 'invalid_token':
      return 'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.';
    case 'network_error':
      return 'ارتباط برقرار نشد. اتصال اینترنت را چک کنید و دوباره تلاش کنید.';
    default:
      return serverMessage.isNotEmpty ? serverMessage : 'خطای ناشناخته ($code)';
  }
}

SalesApiException salesExceptionFrom(
  String code,
  String serverMessage, {
  int? statusCode,
  Map<String, String>? fields,
  int? retryAfterSeconds,
}) {
  return SalesApiException(
    code,
    mapSalesErrorMessage(code, serverMessage, fields: fields, retryAfterSeconds: retryAfterSeconds),
    statusCode: statusCode,
    fields: fields,
    retryAfterSeconds: retryAfterSeconds,
  );
}

SalesApiException _wrapApiException(ApiException e, {int? retryAfterSeconds}) {
  if (e is SalesApiException) return e;
  return salesExceptionFrom(
    e.code,
    e.message,
    statusCode: e.statusCode,
    fields: e.fields,
    retryAfterSeconds: retryAfterSeconds ?? e.retryAfterSeconds,
  );
}

/// Typed sales API. Reuses [FfiApi] JWT store + refresh via [ApiClient] / [Endpoints].
class SalesApi {
  SalesApi(this.ffiApi);

  final FfiApi ffiApi;
  Future<bool>? _refreshing;
  static const _uuid = Uuid();

  ApiClient get _client => ffiApi.client;
  bool get isLoggedIn => ffiApi.isLoggedIn;
  String get baseUrl => ffiApi.baseUrl;

  /// Generate a fresh Idempotency-Key (UUID v4, 36 chars ⊂ 1–64 API limit).
  /// Call **once per purchase attempt**; reuse the same value on retry of that attempt.
  static String newIdempotencyKey() {
    final k = _uuid.v4();
    assert(k.isNotEmpty && k.length <= 64);
    return k;
  }

  // ---------- public ----------

  Future<List<Plan>> getPlans() async {
    try {
      final data = await _client.get(Endpoints.plans);
      return Plan.listFromData(data);
    } on ApiException catch (e) {
      throw _wrapApiException(e);
    }
  }

  // ---------- authenticated ----------

  Future<Wallet> getWallet() async {
    final data = await _authed((access) => _client.get(Endpoints.wallet, bearer: access));
    return Wallet.fromJson(data);
  }

  Future<List<Subscription>> getSubscriptions() async {
    final data = await _authed((access) => _client.get(Endpoints.subscriptions, bearer: access));
    return Subscription.listFromData(data);
  }

  /// Purchase [planId]. Always sends `Idempotency-Key` header.
  /// Pass the **same** [idempotencyKey] on retry of the same attempt; mint a new
  /// one only via [SalesState.beginPurchaseAttempt] / after success or 409 conflict.
  Future<PurchaseResult> purchasePlan(int planId, {required String idempotencyKey}) async {
    final key = idempotencyKey.trim();
    if (key.isEmpty || key.length > 64) {
      throw SalesApiException(
        'validation_error',
        'Idempotency-Key نامعتبر است.',
        statusCode: 422,
      );
    }
    final data = await _authed(
      (access) => _client.post(
        Endpoints.purchase,
        {'plan_id': planId},
        bearer: access,
        headers: {'Idempotency-Key': key},
      ),
    );
    return PurchaseResult.fromJson(data);
  }

  /// Soft-cancel subscription (no Idempotency-Key). Idempotent if already cancelled.
  Future<CancelSubscriptionResult> cancelSubscription(int id) async {
    final data = await _authed(
      (access) => _client.post(
        Endpoints.subscriptionCancel(id),
        const {},
        bearer: access,
      ),
    );
    return CancelSubscriptionResult.fromJson(data);
  }

  /// Renew subscription. Always sends `Idempotency-Key` (same pattern as purchase).
  Future<PurchaseResult> renewSubscription(int id, {required String idempotencyKey}) async {
    final key = idempotencyKey.trim();
    if (key.isEmpty || key.length > 64) {
      throw SalesApiException(
        'validation_error',
        'Idempotency-Key نامعتبر است.',
        statusCode: 422,
      );
    }
    final data = await _authed(
      (access) => _client.post(
        Endpoints.subscriptionRenew(id),
        const {},
        bearer: access,
        headers: {'Idempotency-Key': key},
      ),
    );
    return PurchaseResult.fromJson(data);
  }

  Future<List<ApiKey>> getKeys() async {
    final data = await _authed((access) => _client.get(Endpoints.keys, bearer: access));
    return ApiKey.listFromData(data);
  }

  Future<CreateKeyResult> createKey({String? name, bool saveLocally = true}) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    final data = await _authed(
      (access) => _client.post(Endpoints.keys, body, bearer: access),
    );
    final result = CreateKeyResult.fromJson(data);
    if (saveLocally && result.apiKey.startsWith('apiv1_')) {
      await ffiApi.saveCreatedApiKey(
        id: result.key.id,
        name: result.key.name,
        display: result.key.display,
        raw: result.apiKey,
        calendarTypes: result.key.calendarTypes,
      );
    }
    return result;
  }

  Future<ApiKey> revokeKey(int id) async {
    final data = await _authed((access) => _client.delete(Endpoints.key(id), bearer: access));
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final key = map['key'];
    await ffiApi.removeLocalApiKey(id);
    return ApiKey.fromJson(key is Map ? Map<String, dynamic>.from(key) : <String, dynamic>{});
  }

  // ---------- auth helpers (mirror FfiApi._authed; refresh via ApiClient) ----------

  Future<dynamic> _authed(Future<dynamic> Function(String access) call) async {
    final access = ffiApi.store.accessToken;
    if (access == null || access.isEmpty) {
      if (!await _refresh()) throw await _forceRelogin();
    }
    try {
      return await call(ffiApi.store.accessToken!);
    } on ApiException catch (e) {
      if (e.isTokenExpired) {
        if (await _refresh()) {
          try {
            return await call(ffiApi.store.accessToken!);
          } on ApiException catch (e2) {
            if (e2.isInvalidToken || e2.isTokenExpired) throw await _forceRelogin();
            throw _wrapApiException(e2);
          }
        }
        throw await _forceRelogin();
      }
      if (e.isInvalidToken) throw await _forceRelogin();
      throw _wrapApiException(e);
    }
  }

  Future<bool> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refresh = ffiApi.store.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final data = await _client.post(Endpoints.refresh, {
        'refresh_token': refresh,
        'device_id': ffiApi.store.deviceId,
      });
      final tokens = AuthTokens.tryParse(data);
      if (tokens == null) return false;
      await ffiApi.store.saveTokens(access: tokens.access, refresh: tokens.refresh);
      return true;
    } on ApiException catch (e) {
      if (e.isNetwork) rethrow;
      return false;
    }
  }

  Future<ApiException> _forceRelogin() async {
    await ffiApi.store.clear();
    ffiApi.signalAuthChanged();
    return const ApiException('invalid_token', 'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.');
  }
}
